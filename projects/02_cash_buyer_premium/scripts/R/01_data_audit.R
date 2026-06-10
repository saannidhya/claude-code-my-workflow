#' 01: National CoreLogic cash/mortgage/investor flag coverage audit.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "01_data_audit.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 01_data_audit at ", Sys.time())

con <- open_corelogic_duckdb()
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

ot_path <- sql_quote_path(ot_parquet_glob())

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW ot_raw AS
  SELECT
    TRY_CAST(clip AS BIGINT) AS clip,
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
    TRY_CAST(year AS INTEGER) AS file_year,
    fips_code,
    substr(fips_code, 1, 5) AS county_fips
  FROM read_parquet('{ot_path}', union_by_name = true)
"))

dbExecute(con, "
  CREATE OR REPLACE TEMP VIEW ot AS
  SELECT
    *,
    CAST(floor(sale_raw / 10000) AS INTEGER) AS sale_year,
    CAST(floor(sale_raw / 100) % 100 AS INTEGER) AS sale_month,
    CAST(CAST(floor(sale_raw / 10000) AS INTEGER) * 100
         + CAST(floor(sale_raw / 100) % 100 AS INTEGER) AS INTEGER) AS sale_ym,
    CASE WHEN sale_amount BETWEEN 10000 AND 10000000 THEN 1 ELSE 0 END AS valid_price,
    CASE WHEN residential_indicator = 'Y' OR residential_indicator IS NULL THEN 1 ELSE 0 END AS residential_ok,
    CASE WHEN cash IN (0, 1) THEN 1 ELSE 0 END AS cash_populated,
    CASE WHEN mortgage IN (0, 1) THEN 1 ELSE 0 END AS mortgage_populated,
    CASE WHEN investor IN (0, 1) THEN 1 ELSE 0 END AS investor_populated
  FROM ot_raw
  WHERE sale_raw BETWEEN 20070101 AND 20241231
")

state_year_coverage <- dbGetQuery(con, "
  SELECT
    state,
    sale_year,
    COUNT(*) AS n_rows,
    SUM(valid_price) AS n_valid_price,
    SUM(residential_ok) AS n_residential_ok,
    SUM(cash_populated) AS n_cash_populated,
    SUM(mortgage_populated) AS n_mortgage_populated,
    SUM(investor_populated) AS n_investor_populated,
    AVG(CASE WHEN cash_populated = 1 THEN cash ELSE NULL END) AS cash_share,
    AVG(CASE WHEN mortgage_populated = 1 THEN mortgage ELSE NULL END) AS mortgage_share,
    AVG(CASE WHEN investor_populated = 1 THEN investor ELSE NULL END) AS investor_share,
    AVG(corporate_buyer) AS corporate_buyer_share,
    AVG(foreclosure_reo) AS foreclosure_reo_share,
    AVG(foreclosure_reo_sale) AS foreclosure_reo_sale_share,
    median(CASE WHEN valid_price = 1 THEN sale_amount ELSE NULL END) AS median_price
  FROM ot
  WHERE sale_year BETWEEN 2007 AND 2024
  GROUP BY state, sale_year
  ORDER BY state, sale_year
")

national_year <- dbGetQuery(con, "
  SELECT
    sale_year,
    COUNT(*) AS n_rows,
    SUM(valid_price) AS n_valid_price,
    AVG(CASE WHEN cash_populated = 1 THEN cash ELSE NULL END) AS cash_share,
    AVG(CASE WHEN mortgage_populated = 1 THEN mortgage ELSE NULL END) AS mortgage_share,
    AVG(CASE WHEN investor_populated = 1 THEN investor ELSE NULL END) AS investor_share,
    AVG(corporate_buyer) AS corporate_buyer_share,
    AVG(CASE WHEN cash = 1 AND investor = 1 THEN 1 ELSE 0 END) AS cash_investor_share_all,
    AVG(CASE WHEN cash = 1 AND corporate_buyer = 1 THEN 1 ELSE 0 END) AS cash_corporate_share_all,
    SUM(CASE WHEN cash = 1 THEN 1 ELSE 0 END) AS n_cash,
    SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) AS n_mortgage,
    median(CASE WHEN valid_price = 1 AND cash = 1 THEN sale_amount ELSE NULL END) AS med_cash_price,
    median(CASE WHEN valid_price = 1 AND mortgage = 1 THEN sale_amount ELSE NULL END) AS med_mortgage_price,
    median(CASE WHEN valid_price = 1 THEN sale_amount ELSE NULL END) AS med_all_price
  FROM ot
  WHERE sale_year BETWEEN 2007 AND 2024
    AND residential_ok = 1
  GROUP BY sale_year
  ORDER BY sale_year
")

monthly_finance <- dbGetQuery(con, "
  SELECT
    sale_ym,
    sale_year,
    sale_month,
    COUNT(*) AS n_rows,
    SUM(valid_price) AS n_valid_price,
    AVG(CASE WHEN cash_populated = 1 THEN cash ELSE NULL END) AS cash_share,
    AVG(CASE WHEN mortgage_populated = 1 THEN mortgage ELSE NULL END) AS mortgage_share,
    AVG(CASE WHEN investor_populated = 1 THEN investor ELSE NULL END) AS investor_share,
    AVG(corporate_buyer) AS corporate_buyer_share,
    median(CASE WHEN valid_price = 1 AND cash = 1 THEN sale_amount ELSE NULL END) AS med_cash_price,
    median(CASE WHEN valid_price = 1 AND mortgage = 1 THEN sale_amount ELSE NULL END) AS med_mortgage_price
  FROM ot
  WHERE sale_year BETWEEN 2007 AND 2024
    AND sale_month BETWEEN 1 AND 12
    AND residential_ok = 1
  GROUP BY sale_ym, sale_year, sale_month
  HAVING COUNT(*) >= 1000
  ORDER BY sale_ym
")

buyer_type_year <- dbGetQuery(con, "
  SELECT
    sale_year,
    CASE
      WHEN cash = 1 AND investor = 1 AND corporate_buyer = 1 THEN 'cash_investor_corporate'
      WHEN cash = 1 AND investor = 1 THEN 'cash_investor_noncorporate'
      WHEN cash = 1 AND corporate_buyer = 1 THEN 'cash_corporate_not_investor'
      WHEN cash = 1 THEN 'cash_other'
      WHEN mortgage = 1 THEN 'mortgage'
      ELSE 'other_or_unknown'
    END AS buyer_finance_type,
    COUNT(*) AS n_rows,
    median(CASE WHEN valid_price = 1 THEN sale_amount ELSE NULL END) AS median_price
  FROM ot
  WHERE sale_year BETWEEN 2007 AND 2024
    AND residential_ok = 1
  GROUP BY sale_year, buyer_finance_type
  ORDER BY sale_year, buyer_finance_type
")

write_csv_strict(state_year_coverage, path(tables_dir, "state_year_flag_coverage.csv"))
write_csv_strict(national_year, path(tables_dir, "national_year_finance_shares.csv"))
write_csv_strict(monthly_finance, path(tables_dir, "monthly_finance_shares.csv"))
write_csv_strict(buyer_type_year, path(tables_dir, "buyer_type_year.csv"))

message("State-year rows: ", nrow(state_year_coverage))
message("National-year rows: ", nrow(national_year))
message("Monthly rows: ", nrow(monthly_finance))
message("Finished 01_data_audit at ", Sys.time())
