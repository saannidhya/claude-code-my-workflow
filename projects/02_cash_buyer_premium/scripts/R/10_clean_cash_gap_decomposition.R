#' 10: Clean and canonical cash-gap decomposition.
#'
#' Builds two draft-facing objects:
#' 1. A sequential cash-gap decomposition from all cash to clean ordinary cash.
#' 2. A mutually exclusive cash-type decomposition using the canonical priority
#'    taxonomy: distress > investor > corporate > ordinary.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "10_clean_cash_gap_decomposition.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 10_clean_cash_gap_decomposition at ", Sys.time())

coverage_csv <- path(tables_dir, "unknown_finance_share_state_year.csv")
if (!file_exists(coverage_csv)) {
  stop("Missing finance coverage audit. Run 08_classification_audit.R first: ", coverage_csv)
}

con <- open_corelogic_duckdb(memory_limit = "16GB")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

ot_path <- sql_quote_path(ot_parquet_glob())
prop_path <- sql_quote_path(prop_parquet_glob())
coverage_path <- sql_quote_path(gsub("\\\\", "/", normalizePath(coverage_csv, winslash = "/", mustWork = TRUE)))

coverage_threshold <- 0.05

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW finance_coverage AS
  SELECT
    state,
    TRY_CAST(sale_year AS INTEGER) AS sale_year,
    TRY_CAST(other_or_unknown_finance_share AS DOUBLE) AS other_or_unknown_finance_share
  FROM read_csv_auto('{coverage_path}', header = true)
"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW ot AS
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
    TRY_CAST(new_construction_indicator AS INTEGER) AS new_construction,
    TRY_CAST(foreclosure_reo_indicator AS INTEGER) AS foreclosure_reo,
    TRY_CAST(foreclosure_reo_sale_indicator AS INTEGER) AS foreclosure_reo_sale,
    residential_indicator,
    state,
    substr(fips_code, 1, 5) AS county_fips
  FROM read_parquet('{ot_path}', union_by_name = true)
  WHERE TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 20180101 AND 20241231
    AND TRY_CAST(sale_amount AS DOUBLE) BETWEEN 10000 AND 10000000
    AND TRY_CAST(cash_purchase_indicator AS INTEGER) IN (0, 1)
    AND TRY_CAST(mortgage_purchase_indicator AS INTEGER) IN (0, 1)
"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW prop AS
  SELECT
    TRY_CAST(clip AS BIGINT) AS clip,
    property_indicator_code,
    TRY_CAST(total_number_of_bedrooms_all_buildings AS DOUBLE) AS bedrooms,
    TRY_CAST(total_number_of_bathrooms_all_buildings AS DOUBLE) AS bathrooms,
    TRY_CAST(total_living_area_square_feet_all_buildings AS DOUBLE) AS living_sqft,
    TRY_CAST(universal_building_square_feet AS DOUBLE) AS building_sqft,
    TRY_CAST(year_built AS INTEGER) AS year_built,
    owner_occupancy_code
  FROM read_parquet('{prop_path}', union_by_name = true)
"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP TABLE joined AS
  SELECT
    o.state,
    o.county_fips,
    CAST(floor(o.sale_raw / 10000) AS INTEGER) AS sale_year,
    o.cash,
    o.mortgage,
    COALESCE(o.investor, 0) AS investor,
    COALESCE(o.corporate_buyer, 0) AS corporate_buyer,
    COALESCE(o.new_construction, 0) AS new_construction,
    CASE WHEN o.foreclosure_reo = 1 OR o.foreclosure_reo_sale = 1 THEN 1 ELSE 0 END AS distress,
    ln(o.sale_amount) AS log_price,
    COALESCE(p.property_indicator_code, 'missing') AS property_indicator_code,
    CASE
      WHEN p.bedrooms IS NULL THEN 'bed_missing'
      WHEN p.bedrooms <= 2 THEN 'bed_0_2'
      WHEN p.bedrooms = 3 THEN 'bed_3'
      WHEN p.bedrooms = 4 THEN 'bed_4'
      ELSE 'bed_5plus'
    END AS bed_bin,
    CASE
      WHEN p.bathrooms IS NULL THEN 'bath_missing'
      WHEN p.bathrooms <= 1 THEN 'bath_0_1'
      WHEN p.bathrooms <= 2 THEN 'bath_2'
      WHEN p.bathrooms <= 3 THEN 'bath_3'
      ELSE 'bath_4plus'
    END AS bath_bin,
    CASE
      WHEN COALESCE(p.living_sqft, p.building_sqft) IS NULL THEN 'sqft_missing'
      WHEN COALESCE(p.living_sqft, p.building_sqft) < 1000 THEN 'sqft_lt1000'
      WHEN COALESCE(p.living_sqft, p.building_sqft) < 1500 THEN 'sqft_1000_1499'
      WHEN COALESCE(p.living_sqft, p.building_sqft) < 2000 THEN 'sqft_1500_1999'
      WHEN COALESCE(p.living_sqft, p.building_sqft) < 3000 THEN 'sqft_2000_2999'
      ELSE 'sqft_3000plus'
    END AS sqft_bin,
    CASE
      WHEN p.year_built IS NULL THEN 'built_missing'
      WHEN p.year_built < 1940 THEN 'built_pre1940'
      WHEN p.year_built < 1970 THEN 'built_1940_1969'
      WHEN p.year_built < 1990 THEN 'built_1970_1989'
      WHEN p.year_built < 2010 THEN 'built_1990_2009'
      ELSE 'built_2010plus'
    END AS built_bin,
    COALESCE(p.owner_occupancy_code, 'missing') AS owner_occupancy_code
  FROM ot o
  INNER JOIN finance_coverage fc
    ON o.state = fc.state
   AND CAST(floor(o.sale_raw / 10000) AS INTEGER) = fc.sale_year
   AND fc.other_or_unknown_finance_share <= {coverage_threshold}
  LEFT JOIN prop p
    ON o.clip = p.clip
  WHERE (o.residential_indicator = 'Y' OR o.residential_indicator IS NULL)
    AND o.cash <> o.mortgage
    AND o.county_fips IS NOT NULL
    AND length(o.county_fips) = 5
"))

dbExecute(con, "
  CREATE OR REPLACE TEMP TABLE sequential_cells AS
  WITH stacked AS (
    SELECT 'all_cash_vs_mortgage' AS sample_definition, *
    FROM joined
    UNION ALL
    SELECT 'non_distress_vs_mortgage' AS sample_definition, *
    FROM joined
    WHERE distress = 0
    UNION ALL
    SELECT 'noninstitutional_nondistress_vs_mortgage' AS sample_definition, *
    FROM joined
    WHERE distress = 0
      AND investor = 0
      AND corporate_buyer = 0
    UNION ALL
    SELECT 'clean_ordinary_vs_clean_mortgage' AS sample_definition, *
    FROM joined
    WHERE distress = 0
      AND investor = 0
      AND corporate_buyer = 0
      AND new_construction = 0
  )
  SELECT
    sample_definition,
    state,
    county_fips,
    sale_year,
    property_indicator_code,
    bed_bin,
    bath_bin,
    sqft_bin,
    built_bin,
    owner_occupancy_code,
    COUNT(*) AS n_cell,
    SUM(CASE WHEN cash = 1 THEN 1 ELSE 0 END) AS n_cash,
    SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) AS n_mortgage,
    median(CASE WHEN cash = 1 THEN log_price ELSE NULL END) AS med_log_cash,
    median(CASE WHEN mortgage = 1 THEN log_price ELSE NULL END) AS med_log_mortgage
  FROM stacked
  GROUP BY
    sample_definition, state, county_fips, sale_year, property_indicator_code,
    bed_bin, bath_bin, sqft_bin, built_bin, owner_occupancy_code
  HAVING SUM(CASE WHEN cash = 1 THEN 1 ELSE 0 END) >= 5
     AND SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) >= 5
")

dbExecute(con, "
  CREATE OR REPLACE TEMP TABLE canonical_type_cells AS
  SELECT
    state,
    county_fips,
    sale_year,
    property_indicator_code,
    bed_bin,
    bath_bin,
    sqft_bin,
    built_bin,
    owner_occupancy_code,
    COUNT(*) AS n_cell,
    SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) AS n_mortgage,
    SUM(CASE WHEN cash = 1 AND distress = 1 THEN 1 ELSE 0 END) AS n_cash_distress,
    SUM(CASE WHEN cash = 1 AND distress = 0 AND investor = 1 THEN 1 ELSE 0 END) AS n_cash_investor,
    SUM(CASE WHEN cash = 1 AND distress = 0 AND investor = 0 AND corporate_buyer = 1 THEN 1 ELSE 0 END) AS n_cash_corporate,
    SUM(CASE WHEN cash = 1 AND distress = 0 AND investor = 0 AND corporate_buyer = 0 THEN 1 ELSE 0 END) AS n_cash_ordinary,
    median(CASE WHEN mortgage = 1 THEN log_price ELSE NULL END) AS med_log_mortgage,
    median(CASE WHEN cash = 1 AND distress = 1 THEN log_price ELSE NULL END) AS med_log_cash_distress,
    median(CASE WHEN cash = 1 AND distress = 0 AND investor = 1 THEN log_price ELSE NULL END) AS med_log_cash_investor,
    median(CASE WHEN cash = 1 AND distress = 0 AND investor = 0 AND corporate_buyer = 1 THEN log_price ELSE NULL END) AS med_log_cash_corporate,
    median(CASE WHEN cash = 1 AND distress = 0 AND investor = 0 AND corporate_buyer = 0 THEN log_price ELSE NULL END) AS med_log_cash_ordinary
  FROM joined
  GROUP BY
    state, county_fips, sale_year, property_indicator_code, bed_bin,
    bath_bin, sqft_bin, built_bin, owner_occupancy_code
  HAVING SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) >= 5
")

clean_cash_gap_by_cell_definition <- dbGetQuery(con, "
  SELECT
    sample_definition,
    sale_year,
    COUNT(*) AS n_cells,
    SUM(n_cell) AS n_transactions_in_cells,
    SUM(n_cash) AS n_cash,
    SUM(n_mortgage) AS n_mortgage,
    SUM((n_cash + n_mortgage) * (med_log_cash - med_log_mortgage)) / SUM(n_cash + n_mortgage) AS weighted_log_gap,
    median(med_log_cash - med_log_mortgage) AS median_cell_log_gap
  FROM sequential_cells
  GROUP BY sample_definition, sale_year
  ORDER BY sale_year, sample_definition
")

clean_cash_gap_by_state_year <- dbGetQuery(con, "
  SELECT
    sample_definition,
    state,
    sale_year,
    COUNT(*) AS n_cells,
    SUM(n_cell) AS n_transactions_in_cells,
    SUM(n_cash) AS n_cash,
    SUM(n_mortgage) AS n_mortgage,
    SUM((n_cash + n_mortgage) * (med_log_cash - med_log_mortgage)) / SUM(n_cash + n_mortgage) AS weighted_log_gap,
    median(med_log_cash - med_log_mortgage) AS median_cell_log_gap
  FROM sequential_cells
  GROUP BY sample_definition, state, sale_year
  HAVING SUM(n_cash) >= 50 AND SUM(n_mortgage) >= 50
  ORDER BY sample_definition, state, sale_year
")

canonical_cash_type_gap_by_year <- dbGetQuery(con, "
  WITH long AS (
    SELECT sale_year, 'ordinary_cash' AS cash_type, n_cell, n_mortgage, n_cash_ordinary AS n_cash_type,
           med_log_cash_ordinary - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_ordinary >= 5
    UNION ALL
    SELECT sale_year, 'corporate_cash' AS cash_type, n_cell, n_mortgage, n_cash_corporate AS n_cash_type,
           med_log_cash_corporate - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_corporate >= 5
    UNION ALL
    SELECT sale_year, 'investor_cash' AS cash_type, n_cell, n_mortgage, n_cash_investor AS n_cash_type,
           med_log_cash_investor - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_investor >= 5
    UNION ALL
    SELECT sale_year, 'distress_cash' AS cash_type, n_cell, n_mortgage, n_cash_distress AS n_cash_type,
           med_log_cash_distress - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_distress >= 5
  )
  SELECT
    sale_year,
    cash_type,
    COUNT(*) AS n_cells,
    SUM(n_cash_type) AS n_cash_type,
    SUM(n_mortgage) AS n_mortgage_in_cells,
    SUM((n_cash_type + n_mortgage) * log_gap) / SUM(n_cash_type + n_mortgage) AS weighted_log_gap,
    median(log_gap) AS median_cell_log_gap
  FROM long
  GROUP BY sale_year, cash_type
  ORDER BY sale_year, cash_type
")

canonical_cash_type_gap_by_state_year <- dbGetQuery(con, "
  WITH long AS (
    SELECT state, sale_year, 'ordinary_cash' AS cash_type, n_cell, n_mortgage, n_cash_ordinary AS n_cash_type,
           med_log_cash_ordinary - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_ordinary >= 5
    UNION ALL
    SELECT state, sale_year, 'corporate_cash' AS cash_type, n_cell, n_mortgage, n_cash_corporate AS n_cash_type,
           med_log_cash_corporate - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_corporate >= 5
    UNION ALL
    SELECT state, sale_year, 'investor_cash' AS cash_type, n_cell, n_mortgage, n_cash_investor AS n_cash_type,
           med_log_cash_investor - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_investor >= 5
    UNION ALL
    SELECT state, sale_year, 'distress_cash' AS cash_type, n_cell, n_mortgage, n_cash_distress AS n_cash_type,
           med_log_cash_distress - med_log_mortgage AS log_gap
    FROM canonical_type_cells WHERE n_cash_distress >= 5
  )
  SELECT
    state,
    sale_year,
    cash_type,
    COUNT(*) AS n_cells,
    SUM(n_cash_type) AS n_cash_type,
    SUM(n_mortgage) AS n_mortgage_in_cells,
    SUM((n_cash_type + n_mortgage) * log_gap) / SUM(n_cash_type + n_mortgage) AS weighted_log_gap,
    median(log_gap) AS median_cell_log_gap
  FROM long
  GROUP BY state, sale_year, cash_type
  HAVING SUM(n_cash_type) >= 50
  ORDER BY state, sale_year, cash_type
")

write_csv_strict(clean_cash_gap_by_cell_definition, path(tables_dir, "clean_cash_gap_by_cell_definition.csv"))
write_csv_strict(clean_cash_gap_by_cell_definition, path(tables_dir, "clean_cash_gap_by_year.csv"))
write_csv_strict(clean_cash_gap_by_state_year, path(tables_dir, "clean_cash_gap_by_state_year.csv"))
write_csv_strict(canonical_cash_type_gap_by_year, path(tables_dir, "canonical_cash_type_gap_by_year.csv"))
write_csv_strict(canonical_cash_type_gap_by_state_year, path(tables_dir, "canonical_cash_type_gap_by_state_year.csv"))

sample_labels <- c(
  all_cash_vs_mortgage = "All cash",
  non_distress_vs_mortgage = "Non-distress",
  noninstitutional_nondistress_vs_mortgage = "Non-institutional, non-distress",
  clean_ordinary_vs_clean_mortgage = "Clean ordinary"
)

p_clean_year <- clean_cash_gap_by_cell_definition |>
  mutate(
    sample_definition = factor(sample_labels[sample_definition], levels = sample_labels),
    pct_gap = exp(weighted_log_gap) - 1
  ) |>
  ggplot(aes(x = sale_year, y = pct_gap, color = sample_definition)) +
  geom_hline(yintercept = 0, color = "gray55") +
  geom_line(linewidth = 0.75) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = NULL, y = "Gap vs matched mortgage transactions", color = NULL,
       title = "Sequential decomposition of the cash-mortgage gap") +
  theme(legend.position = "bottom")

p_canonical_type <- canonical_cash_type_gap_by_year |>
  mutate(pct_gap = exp(weighted_log_gap) - 1) |>
  ggplot(aes(x = sale_year, y = pct_gap, color = cash_type)) +
  geom_hline(yintercept = 0, color = "gray55") +
  geom_line(linewidth = 0.75) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = NULL, y = "Gap vs matched mortgage transactions", color = NULL,
       title = "Canonical cash-type gaps by buyer role") +
  theme(legend.position = "bottom")

ggsave(path(figures_dir, "clean_cash_gap_by_year.png"), p_clean_year, width = 8, height = 4.8, dpi = 300)
ggsave(path(figures_dir, "canonical_cash_type_gap_by_year.png"), p_canonical_type, width = 8, height = 4.8, dpi = 300)

message("Sequential clean cash gaps:")
print(clean_cash_gap_by_cell_definition |> mutate(pct_gap = exp(weighted_log_gap) - 1))
message("Canonical cash-type gaps:")
print(canonical_cash_type_gap_by_year |> mutate(pct_gap = exp(weighted_log_gap) - 1))
message("Finished 10_clean_cash_gap_decomposition at ", Sys.time())
