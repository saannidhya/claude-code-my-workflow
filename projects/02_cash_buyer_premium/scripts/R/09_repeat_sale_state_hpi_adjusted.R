#' 09: State-HPI-adjusted repeat-sale intermediation scan.
#'
#' This corrects the first-pass repeat-sale interpretation by recomputing
#' returns from prices with natural logs and subtracting state-year FHFA HPI
#' growth. State HPI is a diagnostic benchmark, not the publication target.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))
source(here::here("projects/02_cash_buyer_premium/scripts/R/repeat_sale_helpers.R"))

log_file <- path(logs_dir, "09_repeat_sale_state_hpi_adjusted.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 09_repeat_sale_state_hpi_adjusted at ", Sys.time())

pairs_csv <- path(tables_dir, "repeat_sale_pairs_2018_2024.csv")
state_hpi_parquet <- here("data", "external", "fhfa_state_hpi.parquet")

if (!file_exists(pairs_csv)) {
  stop("Missing repeat-sale pairs file. Run 06_repeat_sale_intermediation.R first: ", pairs_csv)
}
if (!file_exists(state_hpi_parquet)) {
  stop("Missing FHFA state HPI parquet: ", state_hpi_parquet)
}

con <- open_corelogic_duckdb(memory_limit = "16GB")
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

pairs_path <- sql_quote_path(gsub("\\\\", "/", normalizePath(pairs_csv, winslash = "/", mustWork = TRUE)))
hpi_path <- sql_quote_path(gsub("\\\\", "/", normalizePath(state_hpi_parquet, winslash = "/", mustWork = TRUE)))
pairs_parquet <- sql_quote_path(gsub("\\\\", "/", path(tables_dir, "repeat_sale_hpi_adjusted_pairs.parquet")))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW state_hpi AS
  SELECT
    state_abbr,
    TRY_CAST(year AS INTEGER) AS year,
    TRY_CAST(hpi AS DOUBLE) AS hpi
  FROM read_parquet('{hpi_path}')
"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP TABLE adjusted_pairs AS
  WITH pairs AS (
    SELECT
      TRY_CAST(clip AS BIGINT) AS clip,
      state,
      county_fips,
      TRY_CAST(purchase_year AS INTEGER) AS purchase_year,
      TRY_CAST(resale_year AS INTEGER) AS resale_year,
      purchase_type,
      TRY_CAST(purchase_price AS DOUBLE) AS purchase_price,
      TRY_CAST(resale_price AS DOUBLE) AS resale_price,
      TRY_CAST(holding_years AS DOUBLE) AS holding_years,
      TRY_CAST(resale_cash AS INTEGER) AS resale_cash,
      TRY_CAST(resale_mortgage AS INTEGER) AS resale_mortgage
    FROM read_csv_auto('{pairs_path}', header = true, sample_size = 200000, union_by_name = true)
    WHERE purchase_type <> 'other_or_unknown'
      AND TRY_CAST(purchase_price AS DOUBLE) BETWEEN 10000 AND 10000000
      AND TRY_CAST(resale_price AS DOUBLE) BETWEEN 10000 AND 10000000
      AND TRY_CAST(holding_years AS DOUBLE) BETWEEN 0.5 AND 6
  ),
  joined AS (
    SELECT
      p.*,
      hp.hpi AS purchase_hpi,
      hr.hpi AS resale_hpi,
      CASE
        WHEN p.holding_years >= 0.5 AND p.holding_years < 1 THEN '0.5-1 years'
        WHEN p.holding_years >= 1 AND p.holding_years < 2 THEN '1-2 years'
        WHEN p.holding_years >= 2 AND p.holding_years < 4 THEN '2-4 years'
        WHEN p.holding_years >= 4 AND p.holding_years <= 6 THEN '4-6 years'
        ELSE NULL
      END AS hold_bin
    FROM pairs p
    LEFT JOIN state_hpi hp
      ON p.state = hp.state_abbr
     AND p.purchase_year = hp.year
    LEFT JOIN state_hpi hr
      ON p.state = hr.state_abbr
     AND p.resale_year = hr.year
  )
  SELECT
    *,
    ln(resale_price) - ln(purchase_price) AS realized_ln_return,
    (ln(resale_price) - ln(purchase_price)) / holding_years AS raw_annualized_ln_return,
    CASE
      WHEN purchase_hpi > 0 AND resale_hpi > 0
      THEN ln(resale_hpi) - ln(purchase_hpi)
      ELSE NULL
    END AS state_hpi_ln_growth,
    CASE
      WHEN purchase_hpi > 0 AND resale_hpi > 0
      THEN (ln(resale_hpi) - ln(purchase_hpi)) / holding_years
      ELSE NULL
    END AS state_hpi_annualized_ln_growth,
    CASE
      WHEN purchase_hpi > 0 AND resale_hpi > 0
      THEN ((ln(resale_price) - ln(purchase_price)) - (ln(resale_hpi) - ln(purchase_hpi))) / holding_years
      ELSE NULL
    END AS state_hpi_adjusted_annualized_ln_return
  FROM joined
"))

cutoffs <- dbGetQuery(con, "
  SELECT
    quantile_cont(raw_annualized_ln_return, 0.01) AS raw_p01,
    quantile_cont(raw_annualized_ln_return, 0.99) AS raw_p99,
    quantile_cont(state_hpi_adjusted_annualized_ln_return, 0.01) AS adj_p01,
    quantile_cont(state_hpi_adjusted_annualized_ln_return, 0.99) AS adj_p99
  FROM adjusted_pairs
  WHERE state_hpi_adjusted_annualized_ln_return IS NOT NULL
")

raw_p01 <- cutoffs$raw_p01[[1]]
raw_p99 <- cutoffs$raw_p99[[1]]
adj_p01 <- cutoffs$adj_p01[[1]]
adj_p99 <- cutoffs$adj_p99[[1]]

dbExecute(con, glue("
  CREATE OR REPLACE TEMP TABLE adjusted_pairs_w AS
  SELECT
    *,
    least(greatest(raw_annualized_ln_return, {raw_p01}), {raw_p99}) AS raw_annualized_ln_return_w,
    CASE
      WHEN state_hpi_adjusted_annualized_ln_return IS NULL THEN NULL
      ELSE least(greatest(state_hpi_adjusted_annualized_ln_return, {adj_p01}), {adj_p99})
    END AS state_hpi_adjusted_annualized_ln_return_w
  FROM adjusted_pairs
"))

dbExecute(con, glue("
  COPY (
    SELECT *
    FROM adjusted_pairs_w
  ) TO '{pairs_parquet}' (FORMAT PARQUET, COMPRESSION ZSTD)
"))

merge_coverage <- dbGetQuery(con, "
  SELECT
    state,
    purchase_year,
    resale_year,
    COUNT(*) AS n_pairs,
    SUM(CASE WHEN purchase_hpi IS NOT NULL AND resale_hpi IS NOT NULL THEN 1 ELSE 0 END) AS n_hpi_matched,
    AVG(CASE WHEN purchase_hpi IS NOT NULL AND resale_hpi IS NOT NULL THEN 1 ELSE 0 END) AS hpi_match_share,
    AVG(CASE WHEN purchase_year = resale_year THEN 1 ELSE 0 END) AS same_calendar_year_share
  FROM adjusted_pairs_w
  GROUP BY state, purchase_year, resale_year
  ORDER BY state, purchase_year, resale_year
")

type_summary <- dbGetQuery(con, "
  SELECT
    purchase_type,
    COUNT(*) AS n_pairs,
    SUM(CASE WHEN state_hpi_adjusted_annualized_ln_return IS NOT NULL THEN 1 ELSE 0 END) AS n_hpi_adjusted_pairs,
    AVG(CASE WHEN state_hpi_adjusted_annualized_ln_return IS NOT NULL THEN 1 ELSE 0 END) AS hpi_match_share,
    AVG(CASE WHEN purchase_year = resale_year THEN 1 ELSE 0 END) AS same_calendar_year_share,
    median(holding_years) AS median_hold_years,
    median(purchase_price) AS median_purchase_price,
    median(resale_price) AS median_resale_price,
    mean(raw_annualized_ln_return_w) AS mean_raw_annualized_ln_return_w,
    median(raw_annualized_ln_return) AS median_raw_annualized_ln_return,
    mean(state_hpi_annualized_ln_growth) AS mean_state_hpi_annualized_ln_growth,
    mean(state_hpi_adjusted_annualized_ln_return_w) AS mean_state_hpi_adjusted_annualized_ln_return_w,
    median(state_hpi_adjusted_annualized_ln_return) AS median_state_hpi_adjusted_annualized_ln_return,
    AVG(CASE WHEN resale_cash = 1 THEN 1 ELSE 0 END) AS resale_cash_share,
    AVG(CASE WHEN resale_mortgage = 1 THEN 1 ELSE 0 END) AS resale_mortgage_share
  FROM adjusted_pairs_w
  GROUP BY purchase_type
  ORDER BY
    CASE purchase_type
      WHEN 'mortgage' THEN 1
      WHEN 'ordinary_cash' THEN 2
      WHEN 'corporate_cash' THEN 3
      WHEN 'investor_cash' THEN 4
      WHEN 'distress_cash' THEN 5
      ELSE 6
    END
")

year_type_summary <- dbGetQuery(con, "
  SELECT
    purchase_year,
    purchase_type,
    COUNT(*) AS n_pairs,
    mean(raw_annualized_ln_return_w) AS mean_raw_annualized_ln_return_w,
    mean(state_hpi_adjusted_annualized_ln_return_w) AS mean_state_hpi_adjusted_annualized_ln_return_w,
    median(state_hpi_adjusted_annualized_ln_return) AS median_state_hpi_adjusted_annualized_ln_return
  FROM adjusted_pairs_w
  GROUP BY purchase_year, purchase_type
  ORDER BY purchase_year, purchase_type
")

hold_bin_summary <- dbGetQuery(con, "
  SELECT
    hold_bin,
    purchase_type,
    COUNT(*) AS n_pairs,
    median(holding_years) AS median_hold_years,
    mean(raw_annualized_ln_return_w) AS mean_raw_annualized_ln_return_w,
    mean(state_hpi_adjusted_annualized_ln_return_w) AS mean_state_hpi_adjusted_annualized_ln_return_w,
    median(state_hpi_adjusted_annualized_ln_return) AS median_state_hpi_adjusted_annualized_ln_return
  FROM adjusted_pairs_w
  WHERE hold_bin IS NOT NULL
  GROUP BY hold_bin, purchase_type
  ORDER BY
    CASE hold_bin
      WHEN '0.5-1 years' THEN 1
      WHEN '1-2 years' THEN 2
      WHEN '2-4 years' THEN 3
      WHEN '4-6 years' THEN 4
      ELSE 5
    END,
    purchase_type
")

state_type_summary <- dbGetQuery(con, "
  SELECT
    state,
    purchase_type,
    COUNT(*) AS n_pairs,
    mean(raw_annualized_ln_return_w) AS mean_raw_annualized_ln_return_w,
    mean(state_hpi_adjusted_annualized_ln_return_w) AS mean_state_hpi_adjusted_annualized_ln_return_w,
    median(state_hpi_adjusted_annualized_ln_return) AS median_state_hpi_adjusted_annualized_ln_return
  FROM adjusted_pairs_w
  GROUP BY state, purchase_type
  HAVING COUNT(*) >= 100
  ORDER BY state, purchase_type
")

write_csv_strict(merge_coverage, path(tables_dir, "repeat_sale_hpi_merge_coverage_by_state_year.csv"))
write_csv_strict(type_summary, path(tables_dir, "repeat_sale_hpi_adjusted_by_purchase_type.csv"))
write_csv_strict(year_type_summary, path(tables_dir, "repeat_sale_hpi_adjusted_by_purchase_year_type.csv"))
write_csv_strict(hold_bin_summary, path(tables_dir, "repeat_sale_hpi_adjusted_by_hold_bin.csv"))
write_csv_strict(state_type_summary, path(tables_dir, "repeat_sale_hpi_adjusted_by_state_type.csv"))

type_plot <- type_summary |>
  mutate(
    purchase_type = factor(
      purchase_type,
      levels = c("mortgage", "ordinary_cash", "corporate_cash", "investor_cash", "distress_cash")
    ),
    `Raw repeat-sale return` = exp(mean_raw_annualized_ln_return_w) - 1,
    `State-HPI-adjusted return` = exp(mean_state_hpi_adjusted_annualized_ln_return_w) - 1
  ) |>
  select(purchase_type, `Raw repeat-sale return`, `State-HPI-adjusted return`) |>
  pivot_longer(-purchase_type, names_to = "series", values_to = "pct_return") |>
  ggplot(aes(x = pct_return, y = purchase_type, fill = series)) +
  geom_col(position = position_dodge(width = 0.72), width = 0.64) +
  geom_vline(xintercept = 0, color = "gray55") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  scale_fill_manual(values = c("Raw repeat-sale return" = "#0072B2", "State-HPI-adjusted return" = "#D55E00")) +
  labs(x = "Mean annualized return", y = NULL, fill = NULL,
       title = "Repeat-sale returns net of state HPI growth") +
  theme(legend.position = "bottom")

hold_plot <- hold_bin_summary |>
  mutate(
    purchase_type = factor(
      purchase_type,
      levels = c("mortgage", "ordinary_cash", "corporate_cash", "investor_cash", "distress_cash")
    ),
    hold_bin = factor(hold_bin, levels = c("0.5-1 years", "1-2 years", "2-4 years", "4-6 years")),
    pct_return = exp(mean_state_hpi_adjusted_annualized_ln_return_w) - 1
  ) |>
  ggplot(aes(x = hold_bin, y = pct_return, color = purchase_type, group = purchase_type)) +
  geom_hline(yintercept = 0, color = "gray65") +
  geom_line(linewidth = 0.75) +
  geom_point(size = 1.8) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = NULL, y = "Mean state-HPI-adjusted annualized return", color = NULL,
       title = "State-HPI-adjusted repeat-sale returns by holding period") +
  theme(legend.position = "bottom")

ggsave(path(figures_dir, "repeat_sale_raw_vs_hpi_adjusted_by_purchase_type.png"), type_plot, width = 7.4, height = 4.6, dpi = 300)
ggsave(path(figures_dir, "repeat_sale_hpi_adjusted_by_hold_bin.png"), hold_plot, width = 8, height = 4.8, dpi = 300)

message("Winsorization cutoffs:")
print(cutoffs)
message("State-HPI-adjusted repeat-sale summary:")
print(type_summary |> mutate(
  mean_raw_pct = exp(mean_raw_annualized_ln_return_w) - 1,
  mean_adj_pct = exp(mean_state_hpi_adjusted_annualized_ln_return_w) - 1
))
message("Finished 09_repeat_sale_state_hpi_adjusted at ", Sys.time())
