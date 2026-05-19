#!/usr/bin/env Rscript
#' Wrap prior Stata-era cleaned + geocoded Ohio CSVs as parquet baseline files.
#'
#' READ-ONLY from C:\CoreLogic\housing\. Writes to data/corelogic_baseline/.
#' Usage: Rscript shared_utils/R/wrap_baseline.R

suppressPackageStartupMessages({
  library(arrow)
  library(dplyr)
  library(here)
  library(fs)
  library(readr)
  library(glue)
})

SOURCE_DIR <- "C:/CoreLogic/housing"
TARGET_DIR <- here("data", "corelogic_baseline")
dir_create(TARGET_DIR)

# Mapping: source CSV -> target parquet name
# Target filenames follow the convention load_corelogic_baseline_oh() expects:
#   <dataset>_oh_<variant>.parquet
# where dataset is "ot" or "prop" and variant is anything that makes sense.
MAPPING <- list(
  list(src = "corelogic_ot_oh_2021_2024_cleaned.csv",            dst = "ot_oh_2021_2024_cleaned.parquet"),
  list(src = "corelogic_ownertransfer_geocoded_oh_0724.csv",     dst = "ot_oh_geocoded_2007_2024.parquet"),
  list(src = "corelogic_ownertransfer_geocoded_oh_1620.csv",     dst = "ot_oh_geocoded_2016_2020.parquet"),
  list(src = "corelogic_ownertransfer_geocoded_oh_2124.csv",     dst = "ot_oh_geocoded_2021_2024.parquet"),
  list(src = "corelogic_property_full_geocoded.csv",             dst = "prop_oh_full_geocoded.parquet"),  # national but namespaced as prop_oh_* per loader contract
  list(src = "corelogic_property_full_geocoded_oh.csv",          dst = "prop_oh_geocoded.parquet"),
  list(src = "corelogic_property_geocoded_with_cousub_oh.csv",   dst = "prop_oh_geocoded_with_cousub.parquet"),
  list(src = "corelogic_property_geocoded_with_cousub_place_oh.csv", dst = "prop_oh_geocoded_with_cousub_place.parquet")
)

for (m in MAPPING) {
  src_path <- path(SOURCE_DIR, m$src)
  dst_path <- path(TARGET_DIR, m$dst)

  if (!file_exists(src_path)) {
    cat(glue("SKIP (not found): {m$src}"), "\n", sep = "")
    next
  }

  cat(glue("READ: {m$src}"), "\n", sep = "")
  df <- tryCatch(
    read_csv(src_path, show_col_types = FALSE, progress = FALSE, guess_max = 10000),
    error = function(e) {
      cat(glue("  retry with latin1: {conditionMessage(e)}"), "\n", sep = "")
      read_csv(src_path, show_col_types = FALSE, progress = FALSE, guess_max = 10000,
               locale = locale(encoding = "latin1"))
    }
  )
  cat(glue("  -> {nrow(df)} rows, {ncol(df)} cols"), "\n", sep = "")

  write_parquet(df, dst_path)
  cat(glue("WROTE: {m$dst}"), "\n\n", sep = "")
}

cat("Baseline wrap complete.\n")
