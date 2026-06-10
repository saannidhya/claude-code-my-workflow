#' 02: Stylized facts from audit outputs, with FRED mortgage-rate overlay.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

log_file <- path(logs_dir, "02_stylized_facts.log")
sink(log_file, split = TRUE)
on.exit({
  sink()
}, add = TRUE)

message("Starting 02_stylized_facts at ", Sys.time())

if (!file_exists(fred_mortgage30us_csv)) {
  message("Downloading FRED MORTGAGE30US from: ", fred_mortgage30us_url)
  old_timeout <- getOption("timeout")
  options(timeout = max(300, old_timeout))
  download_ok <- tryCatch({
    utils::download.file(fred_mortgage30us_url, fred_mortgage30us_csv, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) {
    message("FRED download failed; continuing without mortgage-rate overlay: ", conditionMessage(e))
    FALSE
  })
  options(timeout = old_timeout)
}

if (file_exists(fred_mortgage30us_csv)) {
  fred_weekly <- readr::read_csv(fred_mortgage30us_csv, show_col_types = FALSE) |>
    rename(observation_date = observation_date, mortgage30us = MORTGAGE30US) |>
    mutate(
      observation_date = as.Date(observation_date),
      mortgage30us = suppressWarnings(as.numeric(mortgage30us)),
      sale_year = as.integer(format(observation_date, "%Y")),
      sale_month = as.integer(format(observation_date, "%m")),
      sale_ym = sale_year * 100L + sale_month
    ) |>
    filter(!is.na(mortgage30us))

  fred_monthly <- fred_weekly |>
    group_by(sale_ym, sale_year, sale_month) |>
    summarize(mortgage30us = mean(mortgage30us, na.rm = TRUE), .groups = "drop")
} else {
  fred_monthly <- tibble(
    sale_ym = integer(),
    sale_year = integer(),
    sale_month = integer(),
    mortgage30us = numeric()
  )
}

national_year <- readr::read_csv(path(tables_dir, "national_year_finance_shares.csv"), show_col_types = FALSE)
monthly_finance <- readr::read_csv(path(tables_dir, "monthly_finance_shares.csv"), show_col_types = FALSE)
buyer_type_year <- readr::read_csv(path(tables_dir, "buyer_type_year.csv"), show_col_types = FALSE)
state_year <- readr::read_csv(path(tables_dir, "state_year_flag_coverage.csv"), show_col_types = FALSE)

monthly <- monthly_finance |>
  left_join(fred_monthly, by = c("sale_ym", "sale_year", "sale_month")) |>
  mutate(
    date = as.Date(sprintf("%04d-%02d-01", sale_year, sale_month)),
    raw_cash_mortgage_log_gap = log(med_cash_price) - log(med_mortgage_price)
  )

annual_rate <- fred_monthly |>
  group_by(sale_year) |>
  summarize(mortgage30us = mean(mortgage30us, na.rm = TRUE), .groups = "drop")

annual <- national_year |>
  left_join(annual_rate, by = "sale_year") |>
  mutate(
    raw_cash_mortgage_log_gap = log(med_cash_price) - log(med_mortgage_price),
    cash_among_cash_or_mortgage = n_cash / (n_cash + n_mortgage)
  )

state_post_shift <- state_year |>
  filter(sale_year %in% 2019:2024, n_valid_price >= 1000) |>
  mutate(period = if_else(sale_year <= 2021, "pre_2022", "post_2022")) |>
  group_by(state, period) |>
  summarize(
    cash_share = weighted.mean(cash_share, n_valid_price, na.rm = TRUE),
    mortgage_share = weighted.mean(mortgage_share, n_valid_price, na.rm = TRUE),
    investor_share = weighted.mean(investor_share, n_valid_price, na.rm = TRUE),
    corporate_buyer_share = weighted.mean(corporate_buyer_share, n_valid_price, na.rm = TRUE),
    median_price = weighted.mean(median_price, n_valid_price, na.rm = TRUE),
    n_valid_price = sum(n_valid_price, na.rm = TRUE),
    .groups = "drop"
  ) |>
  pivot_wider(
    names_from = period,
    values_from = c(cash_share, mortgage_share, investor_share, corporate_buyer_share, median_price, n_valid_price)
  ) |>
  mutate(
    cash_share_shift = cash_share_post_2022 - cash_share_pre_2022,
    mortgage_share_shift = mortgage_share_post_2022 - mortgage_share_pre_2022,
    investor_share_shift = investor_share_post_2022 - investor_share_pre_2022,
    corporate_share_shift = corporate_buyer_share_post_2022 - corporate_buyer_share_pre_2022
  ) |>
  arrange(desc(cash_share_shift))

write_csv_strict(monthly, path(tables_dir, "monthly_finance_with_mortgage_rates.csv"))
write_csv_strict(annual, path(tables_dir, "annual_finance_with_mortgage_rates.csv"))
write_csv_strict(state_post_shift, path(tables_dir, "state_post_2022_finance_shift.csv"))

p_cash_rate <- ggplot(monthly, aes(x = date)) +
  geom_line(aes(y = cash_share, color = "Cash share"), linewidth = 0.65) +
  geom_line(aes(y = mortgage_share, color = "Mortgage share"), linewidth = 0.65) +
  geom_line(aes(y = mortgage30us / 10, color = "30-year rate / 10"), linewidth = 0.65, na.rm = TRUE) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_color_manual(values = c("Cash share" = "#0072B2", "Mortgage share" = "#009E73", "30-year rate / 10" = "#D55E00")) +
  labs(x = NULL, y = NULL, color = NULL, title = "Cash and mortgage transaction shares") +
  theme(legend.position = "bottom")

p_gap <- ggplot(monthly, aes(x = date, y = raw_cash_mortgage_log_gap)) +
  geom_hline(yintercept = 0, color = "gray60") +
  geom_line(color = "#0072B2", linewidth = 0.65) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = NULL, y = "log median cash price - log median mortgage price", title = "Raw cash-mortgage median price gap")

p_state_shift <- state_post_shift |>
  slice_max(order_by = abs(cash_share_shift), n = 20) |>
  mutate(state = reorder(state, cash_share_shift)) |>
  ggplot(aes(x = cash_share_shift, y = state)) +
  geom_col(fill = "#0072B2") +
  geom_vline(xintercept = 0, color = "gray50") +
  scale_x_continuous(labels = percent_format(accuracy = 1)) +
  labs(x = "Post-2022 minus 2019-2021 cash share", y = NULL, title = "Largest state shifts in cash share")

ggsave(path(figures_dir, "cash_mortgage_shares_with_rate.png"), p_cash_rate, width = 8, height = 4.8, dpi = 300)
ggsave(path(figures_dir, "raw_cash_mortgage_gap_monthly.png"), p_gap, width = 8, height = 4.8, dpi = 300)
ggsave(path(figures_dir, "state_cash_share_shift_post_2022.png"), p_state_shift, width = 7, height = 5.5, dpi = 300)

message("Key annual facts:")
print(annual |> select(sale_year, n_valid_price, cash_share, mortgage_share, mortgage30us, raw_cash_mortgage_log_gap))

message("Largest post-2022 cash-share shifts:")
print(state_post_shift |> select(state, cash_share_shift, mortgage_share_shift, investor_share_shift, corporate_share_shift) |> slice_head(n = 15))

message("Finished 02_stylized_facts at ", Sys.time())
