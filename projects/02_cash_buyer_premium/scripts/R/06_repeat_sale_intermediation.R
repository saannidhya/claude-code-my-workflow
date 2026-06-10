#' 06: Repeat-sale intermediation scan.
#'
#' Exploratory design: consecutive same-parcel transaction pairs, classified by
#' purchase-side buyer type. This is not yet HPI-adjusted.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))
source(here::here("projects/02_cash_buyer_premium/scripts/R/repeat_sale_helpers.R"))

log_file <- path(logs_dir, "06_repeat_sale_intermediation.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 06_repeat_sale_intermediation at ", Sys.time())

con <- open_corelogic_duckdb(memory_limit = "16GB")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

ot_path <- sql_quote_path(ot_parquet_glob())

dbExecute(con, glue("
  CREATE OR REPLACE TEMP TABLE ot_events AS
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
  WHERE TRY_CAST(clip AS BIGINT) IS NOT NULL
    AND TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 20180101 AND 20241231
    AND TRY_CAST(sale_amount AS DOUBLE) BETWEEN 10000 AND 10000000
    AND (residential_indicator = 'Y' OR residential_indicator IS NULL)
    AND substr(fips_code, 1, 5) IS NOT NULL
    AND length(substr(fips_code, 1, 5)) = 5
"))

dbExecute(con, "
  CREATE OR REPLACE TEMP TABLE repeat_pairs AS
  WITH sequenced AS (
    SELECT
      *,
      LEAD(sale_amount) OVER (PARTITION BY clip ORDER BY sale_raw, sale_amount) AS resale_amount,
      LEAD(sale_raw) OVER (PARTITION BY clip ORDER BY sale_raw, sale_amount) AS resale_raw,
      LEAD(cash) OVER (PARTITION BY clip ORDER BY sale_raw, sale_amount) AS resale_cash,
      LEAD(mortgage) OVER (PARTITION BY clip ORDER BY sale_raw, sale_amount) AS resale_mortgage
    FROM ot_events
  ),
  typed AS (
    SELECT
      *,
      CAST(floor(sale_raw / 10000) AS INTEGER) AS purchase_year,
      CAST(floor(resale_raw / 10000) AS INTEGER) AS resale_year,
      datediff(
        'day',
        strptime(CAST(sale_raw AS VARCHAR), '%Y%m%d'),
        strptime(CAST(resale_raw AS VARCHAR), '%Y%m%d')
      ) / 365.25 AS holding_years,
      CASE
        WHEN cash = 1 AND (foreclosure_reo = 1 OR foreclosure_reo_sale = 1) THEN 'distress_cash'
        WHEN cash = 1 AND investor = 1 THEN 'investor_cash'
        WHEN cash = 1 AND corporate_buyer = 1 THEN 'corporate_cash'
        WHEN cash = 1 THEN 'ordinary_cash'
        WHEN (cash IS NULL OR cash = 0) AND mortgage = 1 THEN 'mortgage'
        ELSE 'other_or_unknown'
      END AS purchase_type
    FROM sequenced
    WHERE resale_raw IS NOT NULL
      AND resale_amount BETWEEN 10000 AND 10000000
      AND resale_raw > sale_raw
  )
  SELECT
    clip,
    state,
    county_fips,
    purchase_year,
    resale_year,
    purchase_type,
    cash,
    mortgage,
    investor,
    corporate_buyer,
    foreclosure_reo,
    foreclosure_reo_sale,
    resale_cash,
    resale_mortgage,
    sale_amount AS purchase_price,
    resale_amount AS resale_price,
    ln(sale_amount) AS log_purchase_price,
    ln(resale_amount) AS log_resale_price,
    ln(resale_amount) - ln(sale_amount) AS log_return,
    holding_years,
    (ln(resale_amount) - ln(sale_amount)) / holding_years AS annualized_log_return
  FROM typed
  WHERE purchase_year BETWEEN 2018 AND 2023
    AND resale_year BETWEEN purchase_year AND 2024
    AND holding_years BETWEEN 0.5 AND 6
")

pairs <- dbGetQuery(con, "
  SELECT *
  FROM repeat_pairs
")

pairs <- pairs |>
  mutate(
    purchase_type = factor(
      purchase_type,
      levels = c("mortgage", "ordinary_cash", "corporate_cash", "investor_cash", "distress_cash", "other_or_unknown")
    ),
    annualized_log_return_w = winsorize_vec(annualized_log_return, probs = c(0.01, 0.99)),
    log_return_w = winsorize_vec(log_return, probs = c(0.01, 0.99))
  )

repeat_summary <- pairs |>
  filter(!is.na(purchase_type), purchase_type != "other_or_unknown") |>
  group_by(purchase_type) |>
  summarize(
    n_pairs = n(),
    median_hold_years = median(holding_years, na.rm = TRUE),
    median_purchase_price = median(purchase_price, na.rm = TRUE),
    median_resale_price = median(resale_price, na.rm = TRUE),
    mean_log_return_w = mean(log_return_w, na.rm = TRUE),
    median_log_return = median(log_return, na.rm = TRUE),
    mean_annualized_log_return_w = mean(annualized_log_return_w, na.rm = TRUE),
    median_annualized_log_return = median(annualized_log_return, na.rm = TRUE),
    resale_cash_share = mean(resale_cash == 1, na.rm = TRUE),
    resale_mortgage_share = mean(resale_mortgage == 1, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(purchase_type)

repeat_year_summary <- pairs |>
  filter(!is.na(purchase_type), purchase_type != "other_or_unknown") |>
  group_by(purchase_year, purchase_type) |>
  summarize(
    n_pairs = n(),
    median_hold_years = median(holding_years, na.rm = TRUE),
    mean_annualized_log_return_w = mean(annualized_log_return_w, na.rm = TRUE),
    median_annualized_log_return = median(annualized_log_return, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(purchase_year, purchase_type)

repeat_state_summary <- pairs |>
  filter(!is.na(purchase_type), purchase_type != "other_or_unknown") |>
  group_by(state, purchase_type) |>
  summarize(
    n_pairs = n(),
    mean_annualized_log_return_w = mean(annualized_log_return_w, na.rm = TRUE),
    median_annualized_log_return = median(annualized_log_return, na.rm = TRUE),
    .groups = "drop"
  ) |>
  filter(n_pairs >= 100) |>
  arrange(state, purchase_type)

write_csv_strict(pairs, path(tables_dir, "repeat_sale_pairs_2018_2024.csv"))
write_csv_strict(repeat_summary, path(tables_dir, "repeat_sale_returns_by_purchase_type.csv"))
write_csv_strict(repeat_year_summary, path(tables_dir, "repeat_sale_returns_by_purchase_year_type.csv"))
write_csv_strict(repeat_state_summary, path(tables_dir, "repeat_sale_returns_by_state_type.csv"))

p_type <- repeat_summary |>
  mutate(
    purchase_type = forcats::fct_reorder(purchase_type, mean_annualized_log_return_w),
    pct_return = exp(mean_annualized_log_return_w) - 1
  ) |>
  ggplot(aes(x = pct_return, y = purchase_type)) +
  geom_col(fill = "#0072B2") +
  geom_vline(xintercept = 0, color = "gray55") +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = "Mean annualized repeat-sale return (winsorized log return)", y = NULL,
       title = "Repeat-sale returns by purchase-side buyer type")

p_year <- repeat_year_summary |>
  mutate(pct_return = exp(mean_annualized_log_return_w) - 1) |>
  ggplot(aes(x = purchase_year, y = pct_return, color = purchase_type)) +
  geom_hline(yintercept = 0, color = "gray65") +
  geom_line(linewidth = 0.75) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  labs(x = NULL, y = "Mean annualized return", color = NULL,
       title = "Repeat-sale returns by purchase year and buyer type") +
  theme(legend.position = "bottom")

ggsave(path(figures_dir, "repeat_sale_returns_by_purchase_type.png"), p_type, width = 7, height = 4.4, dpi = 300)
ggsave(path(figures_dir, "repeat_sale_returns_by_purchase_year_type.png"), p_year, width = 8, height = 4.8, dpi = 300)

message("Repeat-sale summary:")
print(repeat_summary)
message("Total pairs: ", nrow(pairs))
message("Finished 06_repeat_sale_intermediation at ", Sys.time())
