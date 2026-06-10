#' 08a: Prior arms-length sale price + date per focal 2007-2010 sale.
#'
#' For the division-bias IV (see quality_reports/peer_review_paper/editorial_decision.md),
#' we instrument the focal log sale price with the parcel's PRIOR arms-length
#' sale price. This script does the heavy duckdb scan: restrict the full OT
#' history to arms-length sales (price >= 5000, not intra-family, not
#' foreclosure), then LAG price + date over each clip to attach, to every focal
#' 2007-2010 sale, the most recent prior arms-length sale's price and date.
#'
#' Output: focal_repeat_sales.parquet  (clip, sale_raw, price, prior_sale_raw, prior_price)

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "PRAGMA threads=4")
tmp_dir <- gsub("\\\\", "/", path(data_dir, "_duckdb_tmp"))
dir_create(tmp_dir)
dbExecute(con, sprintf("PRAGMA temp_directory='%s'", tmp_dir))

ot_glob <- gsub("\\\\", "/", here("data/corelogic_extracts/by_state/ot/**/*.parquet"))
out_path <- gsub("\\\\", "/", path(data_dir, "focal_repeat_sales.parquet"))
log_msg("OT glob: ", ot_glob)

# Arms-length flags are TRY_CAST to VARCHAR for cross-state type-drift safety
# (the flag columns are inferred as different types across state parquets).
log_msg("Scanning OT for prior arms-length sale price + date (LAG over clip)...")
sql <- sprintf("
  COPY (
    WITH al AS (
      SELECT CAST(TRY_CAST(clip AS BIGINT) AS VARCHAR) AS clip,
             TRY_CAST(sale_derived_date AS BIGINT)     AS sale_raw,
             TRY_CAST(sale_amount AS DOUBLE)           AS price
      FROM read_parquet('%s', union_by_name = true)
      WHERE clip IS NOT NULL
        AND sale_derived_date IS NOT NULL
        AND TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 18000101 AND 20251231
        AND TRY_CAST(sale_amount AS DOUBLE) >= 5000
        AND COALESCE(TRY_CAST(interfamily_related_indicator AS VARCHAR), 'N') <> 'Y'
        AND COALESCE(TRY_CAST(foreclosure_reo_indicator   AS VARCHAR), 'N') <> 'Y'
    ),
    ranked AS (
      SELECT clip, sale_raw, price,
             LAG(sale_raw) OVER (PARTITION BY clip ORDER BY sale_raw) AS prior_sale_raw,
             LAG(price)    OVER (PARTITION BY clip ORDER BY sale_raw) AS prior_price
      FROM al
    )
    SELECT clip,
           sale_raw,
           MAX(price)                              AS price,
           MAX(prior_sale_raw)                     AS prior_sale_raw,
           arg_max(prior_price, prior_sale_raw)    AS prior_price
    FROM ranked
    WHERE sale_raw BETWEEN 20070101 AND 20101231
    GROUP BY clip, sale_raw
  ) TO '%s' (FORMAT PARQUET)", ot_glob, out_path)
t0 <- Sys.time()
dbExecute(con, sql)
log_msg("  -> wrote ", out_path, " in ",
        round(difftime(Sys.time(), t0, units = "mins"), 1), " min")

s <- dbGetQuery(con, sprintf("
  SELECT COUNT(*) AS n_focal,
         SUM(CASE WHEN prior_price IS NOT NULL THEN 1 ELSE 0 END) AS n_with_prior
  FROM read_parquet('%s')", out_path))
log_msg("Focal arms-length sales: ", format(s$n_focal, big.mark = ","),
        " | with a prior arms-length sale: ", format(s$n_with_prior, big.mark = ","),
        " (", round(100 * s$n_with_prior / s$n_focal, 1), "%)")

dbDisconnect(con, shutdown = TRUE)
log_msg("DONE — focal_repeat_sales.parquet cached.")
