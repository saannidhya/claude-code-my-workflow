#' 04: Decompose property-adjusted cash gaps by cash-buyer type.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "04_buyer_type_decomposition.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 04_buyer_type_decomposition at ", Sys.time())

con <- open_corelogic_duckdb(memory_limit = "14GB")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

ot_path <- sql_quote_path(ot_parquet_glob())
prop_path <- sql_quote_path(prop_parquet_glob())

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

dbExecute(con, "
  CREATE OR REPLACE TEMP TABLE type_cells AS
  WITH joined AS (
    SELECT
      o.state,
      o.county_fips,
      CAST(floor(o.sale_raw / 10000) AS INTEGER) AS sale_year,
      o.cash,
      o.mortgage,
      o.investor,
      o.corporate_buyer,
      o.foreclosure_reo,
      o.foreclosure_reo_sale,
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
    LEFT JOIN prop p
      ON o.clip = p.clip
    WHERE (o.residential_indicator = 'Y' OR o.residential_indicator IS NULL)
      AND o.cash <> o.mortgage
      AND o.county_fips IS NOT NULL
      AND length(o.county_fips) = 5
  )
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
    SUM(CASE WHEN cash = 1 AND investor = 0 AND corporate_buyer = 0 AND foreclosure_reo = 0 AND foreclosure_reo_sale = 0 THEN 1 ELSE 0 END) AS n_cash_ordinary,
    SUM(CASE WHEN cash = 1 AND corporate_buyer = 1 THEN 1 ELSE 0 END) AS n_cash_corporate,
    SUM(CASE WHEN cash = 1 AND investor = 1 THEN 1 ELSE 0 END) AS n_cash_investor,
    SUM(CASE WHEN cash = 1 AND (foreclosure_reo = 1 OR foreclosure_reo_sale = 1) THEN 1 ELSE 0 END) AS n_cash_distress,
    median(CASE WHEN mortgage = 1 THEN log_price ELSE NULL END) AS med_log_mortgage,
    median(CASE WHEN cash = 1 AND investor = 0 AND corporate_buyer = 0 AND foreclosure_reo = 0 AND foreclosure_reo_sale = 0 THEN log_price ELSE NULL END) AS med_log_cash_ordinary,
    median(CASE WHEN cash = 1 AND corporate_buyer = 1 THEN log_price ELSE NULL END) AS med_log_cash_corporate,
    median(CASE WHEN cash = 1 AND investor = 1 THEN log_price ELSE NULL END) AS med_log_cash_investor,
    median(CASE WHEN cash = 1 AND (foreclosure_reo = 1 OR foreclosure_reo_sale = 1) THEN log_price ELSE NULL END) AS med_log_cash_distress
  FROM joined
  GROUP BY
    state, county_fips, sale_year, property_indicator_code, bed_bin,
    bath_bin, sqft_bin, built_bin, owner_occupancy_code
  HAVING SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) >= 5
")

type_year <- dbGetQuery(con, "
  WITH long AS (
    SELECT sale_year, 'ordinary_cash' AS cash_type, n_cell, n_mortgage, n_cash_ordinary AS n_cash_type,
           med_log_cash_ordinary - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_ordinary >= 5
    UNION ALL
    SELECT sale_year, 'corporate_cash' AS cash_type, n_cell, n_mortgage, n_cash_corporate AS n_cash_type,
           med_log_cash_corporate - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_corporate >= 5
    UNION ALL
    SELECT sale_year, 'investor_cash' AS cash_type, n_cell, n_mortgage, n_cash_investor AS n_cash_type,
           med_log_cash_investor - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_investor >= 5
    UNION ALL
    SELECT sale_year, 'distress_cash' AS cash_type, n_cell, n_mortgage, n_cash_distress AS n_cash_type,
           med_log_cash_distress - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_distress >= 5
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

type_state_year <- dbGetQuery(con, "
  WITH long AS (
    SELECT state, sale_year, 'ordinary_cash' AS cash_type, n_cell, n_mortgage, n_cash_ordinary AS n_cash_type,
           med_log_cash_ordinary - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_ordinary >= 5
    UNION ALL
    SELECT state, sale_year, 'corporate_cash' AS cash_type, n_cell, n_mortgage, n_cash_corporate AS n_cash_type,
           med_log_cash_corporate - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_corporate >= 5
    UNION ALL
    SELECT state, sale_year, 'investor_cash' AS cash_type, n_cell, n_mortgage, n_cash_investor AS n_cash_type,
           med_log_cash_investor - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_investor >= 5
    UNION ALL
    SELECT state, sale_year, 'distress_cash' AS cash_type, n_cell, n_mortgage, n_cash_distress AS n_cash_type,
           med_log_cash_distress - med_log_mortgage AS log_gap
    FROM type_cells WHERE n_cash_distress >= 5
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

write_csv_strict(type_year, path(tables_dir, "cash_type_property_adjusted_gap_by_year.csv"))
write_csv_strict(type_state_year, path(tables_dir, "cash_type_property_adjusted_gap_by_state_year.csv"))

p_type_year <- type_year |>
  mutate(pct_gap = exp(weighted_log_gap) - 1) |>
  ggplot(aes(x = sale_year, y = pct_gap, color = cash_type)) +
  geom_hline(yintercept = 0, color = "gray55") +
  geom_line(linewidth = 0.75) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = NULL, y = "Gap vs mortgage in matched property cells", color = NULL, title = "Property-adjusted cash gaps by buyer type") +
  theme(legend.position = "bottom")

ggsave(path(figures_dir, "cash_type_property_adjusted_gap_by_year.png"), p_type_year, width = 8, height = 4.8, dpi = 300)

message("Cash-type gaps:")
print(type_year |> mutate(pct_gap = exp(weighted_log_gap) - 1))

message("Finished 04_buyer_type_decomposition at ", Sys.time())
