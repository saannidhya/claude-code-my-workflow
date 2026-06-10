#' 08c: Subsequent arms-length sale price + date per focal 2007-2010 sale.
#'
#' The clean SECOND instrument for the division-bias IV, replacing the hedonic
#' (whose exclusion fails — the assessor uses the same characteristics). The
#' parcel's NEXT arms-length sale price is an independent market draw of true
#' value (transitory noise at a different date), and unlike the hedonic it does
#' not share information with the assessor. Together with the prior-sale price
#' (08a) it gives an over-identified IV + a Hansen J test between two
#' valid-class market instruments.
#'
#' Mirrors 08a but uses LEAD (next sale) instead of LAG (prior sale).
#' Output: focal_subsequent_sales.parquet (clip, sale_raw, next_sale_raw, next_price)

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

con <- dbConnect(duckdb::duckdb())
dbExecute(con, "PRAGMA threads=4")
tmp_dir <- gsub("\\\\", "/", path(data_dir, "_duckdb_tmp"))
dir_create(tmp_dir)
dbExecute(con, sprintf("PRAGMA temp_directory='%s'", tmp_dir))

ot_glob <- gsub("\\\\", "/", here("data/corelogic_extracts/by_state/ot/**/*.parquet"))
out_path <- gsub("\\\\", "/", path(data_dir, "focal_subsequent_sales.parquet"))
log_msg("OT glob: ", ot_glob)

log_msg("Scanning OT for subsequent arms-length sale price + date (LEAD over clip)...")
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
             LEAD(sale_raw) OVER (PARTITION BY clip ORDER BY sale_raw) AS next_sale_raw,
             LEAD(price)    OVER (PARTITION BY clip ORDER BY sale_raw) AS next_price
      FROM al
    )
    SELECT clip,
           sale_raw,
           MIN(next_sale_raw)                   AS next_sale_raw,
           arg_min(next_price, next_sale_raw)   AS next_price
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
         SUM(CASE WHEN next_price IS NOT NULL THEN 1 ELSE 0 END) AS n_with_next
  FROM read_parquet('%s')", out_path))
log_msg("Focal sales: ", format(s$n_focal, big.mark = ","),
        " | with a subsequent arms-length sale: ", format(s$n_with_next, big.mark = ","),
        " (", round(100 * s$n_with_next / s$n_focal, 1), "%)")

dbDisconnect(con, shutdown = TRUE)
log_msg("DONE — focal_subsequent_sales.parquet cached.")
