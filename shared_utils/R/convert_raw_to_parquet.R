#!/usr/bin/env Rscript
#' Convert CoreLogic raw extracts to a partitioned parquet store.
#'
#' Inputs:  C:\CoreLogic\housing\{OwnerTransfer,PropertyCharacteristics}\by_state\*.csv  (READ-ONLY)
#' Outputs: data/corelogic_extracts/by_state/{ot,prop}/state=XX[/year=YYYY]/part.parquet
#'          data/corelogic_extracts/_quarantine/<orig_filename>.csv  (junk-state files)
#'          data/corelogic_extracts/_logs/<timestamp>_conversion.log
#'
#' Usage: Rscript shared_utils/R/convert_raw_to_parquet.R [--dry-run]
#'        Rscript shared_utils/R/convert_raw_to_parquet.R --only OH,CA
#'        Rscript shared_utils/R/convert_raw_to_parquet.R --skip-ot --skip-prop
#'
#' Idempotent: re-running overwrites existing partitions (atomically per state).

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(here)
  library(fs)
  library(stringr)
  library(readr)
  library(glue)
})

source(here("shared_utils", "R", "filters.R"))

# ---------- config ----------
RAW_OT_DIR   <- "C:/CoreLogic/housing/OwnerTransfer/by_state"
RAW_PROP_DIR <- "C:/CoreLogic/housing/PropertyCharacteristics/by_state"
OUT_ROOT     <- here("data", "corelogic_extracts")
QUARANTINE   <- path(OUT_ROOT, "_quarantine")
LOG_DIR      <- path(OUT_ROOT, "_logs")

# ---------- arg parsing ----------
args <- commandArgs(trailingOnly = TRUE)
DRY_RUN   <- "--dry-run" %in% args
SKIP_OT   <- "--skip-ot" %in% args
SKIP_PROP <- "--skip-prop" %in% args

only_idx <- which(args == "--only")
ONLY_STATES <- if (length(only_idx) && only_idx < length(args)) {
  toupper(strsplit(args[only_idx + 1], ",")[[1]])
} else {
  NULL  # all valid states
}

# ---------- setup ----------
dir_create(OUT_ROOT)
dir_create(QUARANTINE)
dir_create(LOG_DIR)
log_path <- path(LOG_DIR, format(Sys.time(), "%Y%m%d_%H%M%S_conversion.log"))
log_con  <- file(log_path, "wt")

log_msg <- function(msg) {
  ts <- format(Sys.time(), "%H:%M:%S")
  line <- sprintf("[%s] %s", ts, msg)
  cat(line, "\n", sep = "")
  cat(line, "\n", file = log_con, sep = "")
}

# ---------- conversion logic ----------

#' Normalize CoreLogic column names to snake_case.
#' E.g.,
#'   "SALE AMOUNT" -> "sale_amount"
#'   "APN (PARCEL NUMBER UNFORMATTED)" -> "apn_parcel_number_unformatted"
#'   "SALE DERIVED DATE" -> "sale_derived_date"
#' This makes the parquet store usable from R / Python / Julia without
#' quoting and without per-call rename layers.
normalize_cols <- function(df) {
  newnames <- names(df) |>
    tolower() |>
    gsub("[()/-]", " ", x = _) |>
    gsub("\\s+", "_", x = _) |>
    gsub("_+$", "", x = _) |>
    gsub("^_+", "", x = _)
  # Deduplicate any clashes by appending _2, _3
  dups <- duplicated(newnames)
  if (any(dups)) {
    n <- 2
    while (any(duplicated(newnames))) {
      idx <- which(duplicated(newnames))
      newnames[idx] <- paste0(newnames[idx], "_", n)
      n <- n + 1
    }
  }
  names(df) <- newnames
  df
}

detect_year_col <- function(df) {
  # After normalize_cols(), names are snake_case.
  candidates <- c(
    "sale_derived_date", "sale_date",
    "recording_date", "sale_derived_recording_date",
    "transfer_date", "transaction_batch_date",
    "document_date", "deed_date"
  )
  for (col in candidates) {
    if (col %in% names(df)) return(col)
  }
  NULL
}

extract_year <- function(date_vec) {
  # Try ISO parse first
  parsed <- suppressWarnings(as.Date(date_vec))
  if (any(!is.na(parsed))) return(as.integer(format(parsed, "%Y")))

  # Fall back to YYYYMMDD numeric
  if (is.numeric(date_vec) || all(grepl("^[0-9]{8}$", na.omit(as.character(date_vec))))) {
    return(as.integer(substr(as.character(date_vec), 1, 4)))
  }

  NA_integer_
}

#' Map a few known long-form state names to their 2-char codes.
#' CoreLogic's by-state splitter sometimes emits long names instead of codes.
LONG_NAME_TO_CODE <- c(
  "MASSACHUSETTS" = "MA",
  "CONNECTICUT"   = "CT",
  "NEWHAMPSHIRE"  = "NH",
  "NEWJERSEY"     = "NJ",
  "NEWMEXICO"     = "NM",
  "NEWYORK"       = "NY",
  "NORTHCAROLINA" = "NC",
  "NORTHDAKOTA"   = "ND",
  "RHODEISLAND"   = "RI",
  "SOUTHCAROLINA" = "SC",
  "SOUTHDAKOTA"   = "SD",
  "WESTVIRGINIA"  = "WV"
)

convert_state_csv <- function(csv_path, dataset) {
  fname <- path_file(csv_path)
  raw_token <- str_match(fname, "_([A-Za-z0-9.]+)\\.csv$")[, 2] |> toupper()

  # Map long-form state names to 2-char code if applicable
  state_code <- if (!is.na(raw_token) && raw_token %in% names(LONG_NAME_TO_CODE)) {
    LONG_NAME_TO_CODE[[raw_token]]
  } else {
    raw_token
  }

  if (is.na(state_code) || !is_valid_state_code(state_code)) {
    log_msg(glue("QUARANTINE [{dataset}] {fname} - state token '{raw_token}' not valid"))
    if (!DRY_RUN) {
      file_copy(csv_path, path(QUARANTINE, fname), overwrite = TRUE)
    }
    return(invisible(NULL))
  }

  if (!is.null(ONLY_STATES) && !(state_code %in% ONLY_STATES)) {
    log_msg(glue("SKIP [{dataset}] {fname} - not in --only list"))
    return(invisible(NULL))
  }

  if (DRY_RUN) {
    sz_mb <- round(file_info(csv_path)$size / 1024^2, 1)
    log_msg(glue("KEEP [{dataset}] {fname} ({state_code}) [{sz_mb} MB] - dry-run"))
    return(invisible(NULL))
  }

  log_msg(glue("READ [{dataset}] {fname} ({state_code})"))

  # Try UTF-8, fall back to latin1 on decode error
  df <- tryCatch(
    read_csv(csv_path, show_col_types = FALSE, progress = FALSE,
             guess_max = 10000),
    error = function(e) {
      log_msg(glue("  -> retry with latin1 encoding ({conditionMessage(e)})"))
      read_csv(csv_path, show_col_types = FALSE, progress = FALSE,
               guess_max = 10000,
               locale = locale(encoding = "latin1"))
    }
  )
  n <- nrow(df)
  log_msg(glue("  -> {n} rows, {ncol(df)} cols"))

  if (n == 0) {
    log_msg(glue("  -> SKIP (empty)"))
    return(invisible(NULL))
  }

  # Normalize column names to snake_case so downstream code is consistent.
  df <- normalize_cols(df)

  if (dataset == "ot") {
    # Owner Transfer: partition by state and year
    year_col <- detect_year_col(df)
    if (is.null(year_col)) {
      log_msg(glue("  -> NO YEAR COLUMN; partitioning by state only"))
      df$state <- state_code
      out_dir <- path(OUT_ROOT, "by_state", "ot", glue("state={state_code}"))
      dir_create(out_dir)
      write_parquet(df, path(out_dir, "part.parquet"))
    } else {
      df$state <- state_code
      df$year  <- extract_year(df[[year_col]])
      # Drop rows with unparseable year
      n_bad_year <- sum(is.na(df$year))
      if (n_bad_year > 0) {
        log_msg(glue("  -> {n_bad_year} rows with unparseable year; dropped from partition"))
        df <- df |> filter(!is.na(year))
      }
      write_dataset(
        df,
        path = path(OUT_ROOT, "by_state", "ot"),
        partitioning = c("state", "year"),
        existing_data_behavior = "overwrite"
      )
    }
  } else {
    # Property: partition by state only
    df$state <- state_code
    out_dir <- path(OUT_ROOT, "by_state", "prop", glue("state={state_code}"))
    dir_create(out_dir)
    write_parquet(df, path(out_dir, "part.parquet"))
  }
  log_msg(glue("  -> WROTE parquet"))
}

# ---------- main ----------
log_msg(glue("Conversion started. DRY_RUN={DRY_RUN}, SKIP_OT={SKIP_OT}, SKIP_PROP={SKIP_PROP}"))
log_msg(glue("ONLY_STATES: {if (is.null(ONLY_STATES)) 'ALL' else paste(ONLY_STATES, collapse=',')}"))

if (!SKIP_OT) {
  log_msg("=== OwnerTransfer ===")
  ot_files <- dir_ls(RAW_OT_DIR, glob = "*.csv")
  log_msg(glue("Found {length(ot_files)} OT state files"))
  for (f in ot_files) {
    tryCatch(
      convert_state_csv(f, "ot"),
      error = function(e) log_msg(glue("  ERROR [{path_file(f)}]: {conditionMessage(e)}"))
    )
  }
}

if (!SKIP_PROP) {
  log_msg("=== PropertyCharacteristics ===")
  prop_files <- dir_ls(RAW_PROP_DIR, glob = "*.csv")
  log_msg(glue("Found {length(prop_files)} Prop state files"))
  for (f in prop_files) {
    tryCatch(
      convert_state_csv(f, "prop"),
      error = function(e) log_msg(glue("  ERROR [{path_file(f)}]: {conditionMessage(e)}"))
    )
  }
}

log_msg("Conversion complete.")
close(log_con)
cat(glue("\nLog written to: {log_path}\n"))
