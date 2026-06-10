#' 03: Property-adjusted cash/mortgage price-gap scan.
#'
#' The goal is discovery, not a final causal estimate. We compare cash and
#' mortgage median log prices inside narrow county-year-property cells.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "03_property_adjusted_scan.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 03_property_adjusted_scan at ", Sys.time())

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
    state,
    property_indicator_code,
    land_use_code,
    TRY_CAST(total_number_of_bedrooms_all_buildings AS DOUBLE) AS bedrooms,
    TRY_CAST(total_number_of_bathrooms_all_buildings AS DOUBLE) AS bathrooms,
    TRY_CAST(total_living_area_square_feet_all_buildings AS DOUBLE) AS living_sqft,
    TRY_CAST(universal_building_square_feet AS DOUBLE) AS building_sqft,
    TRY_CAST(total_land_square_footage AS DOUBLE) AS land_sqft,
    TRY_CAST(year_built AS INTEGER) AS year_built,
    owner_occupancy_code,
    substr(situs_zip_code, 1, 5) AS zip5
  FROM read_parquet('{prop_path}', union_by_name = true)
"))

dbExecute(con, "
  CREATE OR REPLACE TEMP TABLE matched_cells AS
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
      o.sale_amount,
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
    SUM(CASE WHEN cash = 1 THEN 1 ELSE 0 END) AS n_cash,
    SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) AS n_mortgage,
    AVG(CASE WHEN cash = 1 THEN investor ELSE NULL END) AS cash_investor_share,
    AVG(CASE WHEN cash = 1 THEN corporate_buyer ELSE NULL END) AS cash_corporate_share,
    AVG(CASE WHEN cash = 1 THEN foreclosure_reo ELSE NULL END) AS cash_foreclosure_share,
    median(CASE WHEN cash = 1 THEN log_price ELSE NULL END) AS med_log_price_cash,
    median(CASE WHEN mortgage = 1 THEN log_price ELSE NULL END) AS med_log_price_mortgage,
    median(CASE WHEN cash = 1 THEN sale_amount ELSE NULL END) AS med_price_cash,
    median(CASE WHEN mortgage = 1 THEN sale_amount ELSE NULL END) AS med_price_mortgage
  FROM joined
  GROUP BY
    state, county_fips, sale_year, property_indicator_code, bed_bin,
    bath_bin, sqft_bin, built_bin, owner_occupancy_code
  HAVING SUM(CASE WHEN cash = 1 THEN 1 ELSE 0 END) >= 5
     AND SUM(CASE WHEN mortgage = 1 THEN 1 ELSE 0 END) >= 5
")

cell_gaps <- dbGetQuery(con, "
  SELECT
    *,
    med_log_price_cash - med_log_price_mortgage AS cash_mortgage_log_gap,
    exp(med_log_price_cash - med_log_price_mortgage) - 1 AS cash_mortgage_pct_gap
  FROM matched_cells
  ORDER BY sale_year, state, county_fips
")

year_gaps <- dbGetQuery(con, "
  SELECT
    sale_year,
    SUM(n_cell) AS n_transactions_in_cells,
    COUNT(*) AS n_cells,
    SUM(n_cash) AS n_cash,
    SUM(n_mortgage) AS n_mortgage,
    SUM(n_cell * (med_log_price_cash - med_log_price_mortgage)) / SUM(n_cell) AS weighted_log_gap,
    median(med_log_price_cash - med_log_price_mortgage) AS median_cell_log_gap,
    SUM(n_cash * cash_investor_share) / SUM(n_cash) AS cash_investor_share,
    SUM(n_cash * cash_corporate_share) / SUM(n_cash) AS cash_corporate_share,
    SUM(n_cash * cash_foreclosure_share) / SUM(n_cash) AS cash_foreclosure_share
  FROM matched_cells
  GROUP BY sale_year
  ORDER BY sale_year
")

state_year_gaps <- dbGetQuery(con, "
  SELECT
    state,
    sale_year,
    SUM(n_cell) AS n_transactions_in_cells,
    COUNT(*) AS n_cells,
    SUM(n_cash) AS n_cash,
    SUM(n_mortgage) AS n_mortgage,
    SUM(n_cell * (med_log_price_cash - med_log_price_mortgage)) / SUM(n_cell) AS weighted_log_gap,
    median(med_log_price_cash - med_log_price_mortgage) AS median_cell_log_gap,
    SUM(n_cash * cash_investor_share) / SUM(n_cash) AS cash_investor_share,
    SUM(n_cash * cash_corporate_share) / SUM(n_cash) AS cash_corporate_share,
    SUM(n_cash * cash_foreclosure_share) / SUM(n_cash) AS cash_foreclosure_share
  FROM matched_cells
  GROUP BY state, sale_year
  HAVING SUM(n_cell) >= 1000
  ORDER BY state, sale_year
")

cash_gap_extremes <- cell_gaps |>
  filter(n_cell >= 50) |>
  arrange(cash_mortgage_log_gap) |>
  bind_rows(
    cell_gaps |>
      filter(n_cell >= 50) |>
      arrange(desc(cash_mortgage_log_gap))
  ) |>
  group_by(state, county_fips, sale_year, property_indicator_code, bed_bin, bath_bin, sqft_bin, built_bin, owner_occupancy_code) |>
  slice_head(n = 1) |>
  ungroup() |>
  arrange(cash_mortgage_log_gap)

write_csv_strict(cell_gaps, path(tables_dir, "property_cell_cash_mortgage_gaps.csv"))
write_csv_strict(year_gaps, path(tables_dir, "property_adjusted_gap_by_year.csv"))
write_csv_strict(state_year_gaps, path(tables_dir, "property_adjusted_gap_by_state_year.csv"))
write_csv_strict(cash_gap_extremes, path(tables_dir, "property_cell_gap_extremes.csv"))

p_year <- year_gaps |>
  mutate(
    weighted_pct_gap = exp(weighted_log_gap) - 1,
    median_cell_pct_gap = exp(median_cell_log_gap) - 1
  ) |>
  ggplot(aes(x = sale_year)) +
  geom_hline(yintercept = 0, color = "gray55") +
  geom_line(aes(y = weighted_pct_gap, color = "Transaction-weighted"), linewidth = 0.75) +
  geom_line(aes(y = median_cell_pct_gap, color = "Median cell"), linewidth = 0.75) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_color_manual(values = c("Transaction-weighted" = "#0072B2", "Median cell" = "#D55E00")) +
  labs(x = NULL, y = "Cash price gap within cells", color = NULL, title = "Property-adjusted cash-mortgage gap") +
  theme(legend.position = "bottom")

p_dist <- cell_gaps |>
  filter(n_cell >= 20, is.finite(cash_mortgage_pct_gap), cash_mortgage_pct_gap > -0.75, cash_mortgage_pct_gap < 0.75) |>
  ggplot(aes(x = cash_mortgage_pct_gap, weight = n_cell)) +
  geom_vline(xintercept = 0, color = "gray55") +
  geom_histogram(bins = 80, fill = "#0072B2", alpha = 0.85) +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Cash-mortgage median price gap within property cells", y = "Transaction-weighted cell count", title = "Distribution of property-adjusted gaps")

p_state_2024 <- state_year_gaps |>
  filter(sale_year == max(sale_year, na.rm = TRUE), n_transactions_in_cells >= 1000) |>
  mutate(weighted_pct_gap = exp(weighted_log_gap) - 1) |>
  slice_max(order_by = abs(weighted_pct_gap), n = 25) |>
  mutate(state = reorder(state, weighted_pct_gap)) |>
  ggplot(aes(x = weighted_pct_gap, y = state)) +
  geom_col(fill = "#0072B2") +
  geom_vline(xintercept = 0, color = "gray55") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Transaction-weighted cash price gap", y = NULL, title = "Largest 2024 state cash-mortgage gaps")

ggsave(path(figures_dir, "property_adjusted_gap_by_year.png"), p_year, width = 7.5, height = 4.5, dpi = 300)
ggsave(path(figures_dir, "property_cell_gap_distribution.png"), p_dist, width = 7.5, height = 4.5, dpi = 300)
ggsave(path(figures_dir, "state_property_adjusted_gap_2024.png"), p_state_2024, width = 7.2, height = 5.2, dpi = 300)

message("Year gaps:")
print(year_gaps)

message("Largest state-year absolute gaps:")
print(
  state_year_gaps |>
    mutate(pct_gap = exp(weighted_log_gap) - 1) |>
    arrange(desc(abs(pct_gap))) |>
    select(state, sale_year, n_transactions_in_cells, n_cash, n_mortgage, pct_gap, cash_investor_share, cash_corporate_share) |>
    slice_head(n = 20)
)

message("Finished 03_property_adjusted_scan at ", Sys.time())
