#' 08: Classification audit for finance and buyer-type flags.
#'
#' This script audits whether cash, mortgage, investor, corporate, and distress
#' indicators can support a canonical buyer taxonomy. It is intentionally
#' CoreLogic-OT-only and uses the 2018--2024 analysis window for the current
#' manuscript's within-cell and repeat-sale evidence.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "08_classification_audit.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 08_classification_audit at ", Sys.time())

con <- open_corelogic_duckdb(memory_limit = "14GB")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

ot_path <- sql_quote_path(ot_parquet_glob())
audit_start_raw <- 20180101L
audit_end_raw <- 20241231L

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW classified AS
  WITH normalized AS (
    SELECT
      state,
      county_fips,
      CAST(floor(sale_raw / 10000) AS INTEGER) AS sale_year,
      sale_amount,
      CASE WHEN cash IN (0, 1) THEN cash ELSE NULL END AS cash,
      CASE WHEN mortgage IN (0, 1) THEN mortgage ELSE NULL END AS mortgage,
      CASE WHEN investor IN (0, 1) THEN investor ELSE NULL END AS investor,
      corporate_buyer,
      CASE WHEN foreclosure_reo = 1 OR foreclosure_reo_sale = 1 THEN 1 ELSE 0 END AS distress,
      CASE WHEN resale IN (0, 1) THEN resale ELSE NULL END AS resale,
      CASE WHEN new_construction IN (0, 1) THEN new_construction ELSE NULL END AS new_construction
    FROM (
      SELECT
        TRY_CAST(sale_amount AS DOUBLE) AS sale_amount,
        TRY_CAST(sale_derived_date AS BIGINT) AS sale_raw,
        TRY_CAST(cash_purchase_indicator AS INTEGER) AS cash,
        TRY_CAST(mortgage_purchase_indicator AS INTEGER) AS mortgage,
        TRY_CAST(investor_purchase_indicator AS INTEGER) AS investor,
        CASE WHEN buyer_1_corporate_indicator = 'Y'
               OR buyer_2_corporate_indicator = 'Y'
               OR buyer_3_corporate_indicator = 'Y'
               OR buyer_4_corporate_indicator = 'Y'
             THEN 1 ELSE 0 END AS corporate_buyer,
        TRY_CAST(resale_indicator AS INTEGER) AS resale,
        TRY_CAST(new_construction_indicator AS INTEGER) AS new_construction,
        TRY_CAST(foreclosure_reo_indicator AS INTEGER) AS foreclosure_reo,
        TRY_CAST(foreclosure_reo_sale_indicator AS INTEGER) AS foreclosure_reo_sale,
        residential_indicator,
        state,
        substr(fips_code, 1, 5) AS county_fips
      FROM read_parquet('{ot_path}', union_by_name = true)
      WHERE TRY_CAST(sale_derived_date AS BIGINT) BETWEEN {audit_start_raw} AND {audit_end_raw}
        AND TRY_CAST(sale_amount AS DOUBLE) BETWEEN 10000 AND 10000000
        AND (residential_indicator = 'Y' OR residential_indicator IS NULL)
    )
  )
  SELECT
    state,
    county_fips,
    sale_year,
    sale_amount,
    cash,
    mortgage,
    investor,
    corporate_buyer,
    distress,
    resale,
    new_construction,
    CASE
      WHEN cash = 1 AND mortgage = 0 THEN 'cash_only'
      WHEN cash = 0 AND mortgage = 1 THEN 'mortgage_only'
      WHEN cash = 1 AND mortgage = 1 THEN 'cash_mortgage_conflict'
      WHEN cash = 0 AND mortgage = 0 THEN 'neither_cash_nor_mortgage'
      ELSE 'finance_flag_missing'
    END AS finance_status,
    CASE
      WHEN cash = 1 AND mortgage = 1 THEN 'cash_mortgage_conflict'
      WHEN cash = 1 AND distress = 1 THEN 'distress_cash'
      WHEN cash = 1 AND investor = 1 THEN 'investor_cash'
      WHEN cash = 1 AND corporate_buyer = 1 THEN 'corporate_cash'
      WHEN cash = 1 THEN 'ordinary_cash'
      WHEN cash = 0 AND mortgage = 1 THEN 'mortgage'
      WHEN cash = 0 AND mortgage = 0 THEN 'noncash_nonmortgage_unknown'
      ELSE 'finance_flag_missing'
    END AS buyer_taxonomy
  FROM normalized
"))

classification_overlap_national_year <- dbGetQuery(con, "
  SELECT
    sale_year,
    finance_status,
    buyer_taxonomy,
    COALESCE(investor, -1) AS investor_flag,
    corporate_buyer,
    distress,
    COUNT(*) AS n_transactions
  FROM classified
  GROUP BY sale_year, finance_status, buyer_taxonomy, investor_flag, corporate_buyer, distress
  ORDER BY sale_year, finance_status, buyer_taxonomy, investor_flag, corporate_buyer, distress
")

classification_overlap_state_year <- dbGetQuery(con, "
  SELECT
    state,
    sale_year,
    finance_status,
    buyer_taxonomy,
    COALESCE(investor, -1) AS investor_flag,
    corporate_buyer,
    distress,
    COUNT(*) AS n_transactions
  FROM classified
  GROUP BY state, sale_year, finance_status, buyer_taxonomy, investor_flag, corporate_buyer, distress
  ORDER BY state, sale_year, finance_status, buyer_taxonomy, investor_flag, corporate_buyer, distress
")

finance_flag_crosswalk_state_year <- dbGetQuery(con, "
  SELECT
    state,
    sale_year,
    COALESCE(cash, -1) AS cash_flag,
    COALESCE(mortgage, -1) AS mortgage_flag,
    finance_status,
    COUNT(*) AS n_transactions
  FROM classified
  GROUP BY state, sale_year, cash_flag, mortgage_flag, finance_status
  ORDER BY state, sale_year, cash_flag, mortgage_flag
")

unknown_finance_share_state_year <- dbGetQuery(con, "
  SELECT
    state,
    sale_year,
    COUNT(*) AS n_transactions,
    SUM(CASE WHEN finance_status = 'cash_only' THEN 1 ELSE 0 END) AS n_cash_only,
    SUM(CASE WHEN finance_status = 'mortgage_only' THEN 1 ELSE 0 END) AS n_mortgage_only,
    SUM(CASE WHEN finance_status = 'cash_mortgage_conflict' THEN 1 ELSE 0 END) AS n_cash_mortgage_conflict,
    SUM(CASE WHEN finance_status = 'neither_cash_nor_mortgage' THEN 1 ELSE 0 END) AS n_neither_cash_nor_mortgage,
    SUM(CASE WHEN finance_status = 'finance_flag_missing' THEN 1 ELSE 0 END) AS n_finance_flag_missing,
    AVG(CASE WHEN finance_status = 'cash_only' THEN 1 ELSE 0 END) AS cash_only_share,
    AVG(CASE WHEN finance_status = 'mortgage_only' THEN 1 ELSE 0 END) AS mortgage_only_share,
    AVG(CASE WHEN finance_status = 'cash_mortgage_conflict' THEN 1 ELSE 0 END) AS cash_mortgage_conflict_share,
    AVG(CASE WHEN finance_status IN ('neither_cash_nor_mortgage', 'finance_flag_missing') THEN 1 ELSE 0 END) AS other_or_unknown_finance_share
  FROM classified
  GROUP BY state, sale_year
  ORDER BY state, sale_year
")

buyer_taxonomy_national_year <- dbGetQuery(con, "
  SELECT
    sale_year,
    buyer_taxonomy,
    COUNT(*) AS n_transactions,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (PARTITION BY sale_year) AS share_transactions
  FROM classified
  GROUP BY sale_year, buyer_taxonomy
  ORDER BY sale_year, buyer_taxonomy
")

cash_overlap_national_year <- dbGetQuery(con, "
  SELECT
    sale_year,
    investor,
    corporate_buyer,
    distress,
    COUNT(*) AS n_cash_transactions,
    median(sale_amount) AS median_sale_price
  FROM classified
  WHERE cash = 1
  GROUP BY sale_year, investor, corporate_buyer, distress
  ORDER BY sale_year, investor, corporate_buyer, distress
")

write_csv_strict(classification_overlap_national_year, path(tables_dir, "classification_overlap_national_year.csv"))
write_csv_strict(classification_overlap_state_year, path(tables_dir, "classification_overlap_state_year.csv"))
write_csv_strict(finance_flag_crosswalk_state_year, path(tables_dir, "finance_flag_crosswalk_state_year.csv"))
write_csv_strict(unknown_finance_share_state_year, path(tables_dir, "unknown_finance_share_state_year.csv"))
write_csv_strict(buyer_taxonomy_national_year, path(tables_dir, "buyer_taxonomy_national_year.csv"))
write_csv_strict(cash_overlap_national_year, path(tables_dir, "cash_overlap_national_year.csv"))

message("National overlap rows: ", nrow(classification_overlap_national_year))
message("State-year overlap rows: ", nrow(classification_overlap_state_year))
message("Finished 08_classification_audit at ", Sys.time())
