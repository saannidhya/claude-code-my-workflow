#' 03: Compute parcel-level transaction-frequency measures for the H6 test.
#'
#' H6 (novel mechanism): properties that transact more frequently give the
#' assessor fresher market information, so their assessment ratios are closer
#' to 1.0. If low-priced homes turn over more (or less) often than high-priced
#' homes, transaction frequency may MEDIATE the within-jurisdiction regressivity
#' documented in Phase 1.
#'
#' This script does the heavy data engineering: a full scan of the OT store
#' (ALL years 1900-2024, not just the 2007-2010 analysis window) to compute,
#' per parcel (`clip`):
#'   - n_txn_total        : count of all recorded transactions
#'   - first/last_sale_raw : YYYYMMDD of first and last recorded sale
#' and, for each focal 2007-2010 sale:
#'   - prior_sale_raw     : YYYYMMDD of the immediately preceding sale (LAG)
#'     -> years_since_prior_sale = staleness of the assessor's info at sale
#'
#' Engine: duckdb (out-of-core; far faster than dplyr for the big window
#' sort — see the 45-min dplyr dedup in 01_clean for why we switched).
#'
#' Caveat (documented for the eventual paper): n_txn_total counts ALL deed
#' types (arms-length resales, intra-family transfers, foreclosures, some
#' refinance recordings). A refinement counts arms-length only; deferred to a
#' robustness pass because the arms-length flag columns have cross-state type
#' drift that complicates the full-store scan.
#'
#' Outputs (gitignored, under data/derived/01_property_tax_regressivity/):
#'   - clip_frequency.parquet      one row per clip
#'   - focal_txn_lag.parquet       one row per focal 2007-2010 transaction

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

# ---- duckdb setup ----
con <- dbConnect(duckdb::duckdb())
dbExecute(con, "PRAGMA threads=4")
tmp_dir <- gsub("\\\\", "/", path(data_dir, "_duckdb_tmp"))
dir_create(tmp_dir)
dbExecute(con, sprintf("PRAGMA temp_directory='%s'", tmp_dir))

ot_glob <- gsub("\\\\", "/", here("data/corelogic_extracts/by_state/ot/**/*.parquet"))
log_msg("OT glob: ", ot_glob)

freq_out <- gsub("\\\\", "/", path(data_dir, "clip_frequency.parquet"))
lag_out  <- gsub("\\\\", "/", path(data_dir, "focal_txn_lag.parquet"))

# ---- 1. Per-clip transaction frequency (full history) ----
log_msg("Computing per-clip transaction frequency (full OT history)...")
freq_sql <- sprintf("
  COPY (
    SELECT CAST(TRY_CAST(clip AS BIGINT) AS VARCHAR) AS clip,
           COUNT(*)                                   AS n_txn_total,
           MIN(TRY_CAST(sale_derived_date AS BIGINT)) AS first_sale_raw,
           MAX(TRY_CAST(sale_derived_date AS BIGINT)) AS last_sale_raw
    FROM read_parquet('%s', union_by_name = true)
    WHERE clip IS NOT NULL
      AND sale_derived_date IS NOT NULL
      AND TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 18000101 AND 20251231
    GROUP BY clip
  ) TO '%s' (FORMAT PARQUET)", ot_glob, freq_out)
t0 <- Sys.time()
dbExecute(con, freq_sql)
log_msg("  -> wrote ", freq_out, " in ",
        round(difftime(Sys.time(), t0, units = "mins"), 1), " min")

# ---- 2. Focal-transaction lag (prior sale via window over full history) ----
log_msg("Computing focal-transaction lag (LAG over full history, output 2007-2010)...")
lag_sql <- sprintf("
  COPY (
    WITH ranked AS (
      SELECT CAST(TRY_CAST(clip AS BIGINT) AS VARCHAR) AS clip,
             TRY_CAST(sale_derived_date AS BIGINT)    AS sale_raw,
             LAG(TRY_CAST(sale_derived_date AS BIGINT)) OVER (
               PARTITION BY clip
               ORDER BY TRY_CAST(sale_derived_date AS BIGINT)
             )                                        AS prior_sale_raw
      FROM read_parquet('%s', union_by_name = true)
      WHERE clip IS NOT NULL
        AND sale_derived_date IS NOT NULL
        AND TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 18000101 AND 20251231
    )
    SELECT clip, sale_raw, MIN(prior_sale_raw) AS prior_sale_raw
    FROM ranked
    WHERE sale_raw BETWEEN 20070101 AND 20101231
    GROUP BY clip, sale_raw
  ) TO '%s' (FORMAT PARQUET)", ot_glob, lag_out)
t0 <- Sys.time()
dbExecute(con, lag_sql)
log_msg("  -> wrote ", lag_out, " in ",
        round(difftime(Sys.time(), t0, units = "mins"), 1), " min")

# ---- quick summaries ----
freq_summary <- dbGetQuery(con, sprintf("
  SELECT COUNT(*) AS n_clips,
         AVG(n_txn_total) AS mean_n_txn,
         MEDIAN(n_txn_total) AS median_n_txn,
         MAX(n_txn_total) AS max_n_txn
  FROM read_parquet('%s')", freq_out))
log_msg("Frequency table: ", format(freq_summary$n_clips, big.mark = ","),
        " clips | mean n_txn = ", round(freq_summary$mean_n_txn, 2),
        " | median = ", freq_summary$median_n_txn,
        " | max = ", freq_summary$max_n_txn)

lag_summary <- dbGetQuery(con, sprintf("
  SELECT COUNT(*) AS n_focal,
         SUM(CASE WHEN prior_sale_raw IS NULL THEN 1 ELSE 0 END) AS n_no_prior
  FROM read_parquet('%s')", lag_out))
log_msg("Focal lag table: ", format(lag_summary$n_focal, big.mark = ","),
        " focal sales | ", format(lag_summary$n_no_prior, big.mark = ","),
        " with no prior sale (first-ever recorded)")

dbDisconnect(con, shutdown = TRUE)
log_msg("DONE — frequency measures cached.")
