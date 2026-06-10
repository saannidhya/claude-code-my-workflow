#' 05: Write initial discovery report from generated tables.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

pct <- function(x, accuracy = 0.1) {
  scales::percent(x, accuracy = accuracy)
}

pp <- function(x) {
  paste0(round(100 * x, 1), " pp")
}

annual <- readr::read_csv(path(tables_dir, "annual_finance_with_mortgage_rates.csv"), show_col_types = FALSE)
state_shift <- readr::read_csv(path(tables_dir, "state_post_2022_finance_shift.csv"), show_col_types = FALSE)
year_gaps <- readr::read_csv(path(tables_dir, "property_adjusted_gap_by_year.csv"), show_col_types = FALSE) |>
  mutate(weighted_pct_gap = exp(weighted_log_gap) - 1,
         median_cell_pct_gap = exp(median_cell_log_gap) - 1)
type_gaps <- readr::read_csv(path(tables_dir, "cash_type_property_adjusted_gap_by_year.csv"), show_col_types = FALSE) |>
  mutate(pct_gap = exp(weighted_log_gap) - 1,
         median_cell_pct_gap = exp(median_cell_log_gap) - 1)

total_valid <- sum(annual$n_valid_price, na.rm = TRUE)
cash_min <- annual |> slice_min(cash_share, n = 1, with_ties = FALSE)
cash_max <- annual |> slice_max(cash_share, n = 1, with_ties = FALSE)
top_shift <- state_shift |>
  arrange(desc(cash_share_shift)) |>
  slice_head(n = 8)

gap_2018 <- year_gaps |> filter(sale_year == 2018) |> slice(1)
gap_2024 <- year_gaps |> filter(sale_year == 2024) |> slice(1)

type_latest <- type_gaps |>
  filter(sale_year == max(sale_year, na.rm = TRUE)) |>
  arrange(cash_type)

type_summary <- type_gaps |>
  group_by(cash_type) |>
  summarize(
    min_gap = min(pct_gap, na.rm = TRUE),
    max_gap = max(pct_gap, na.rm = TRUE),
    mean_gap = mean(pct_gap, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(mean_gap)

year_gap_lines <- year_gaps |>
  transmute(
    line = sprintf(
      "| %d | %s | %s | %s | %s |",
      sale_year,
      format(n_transactions_in_cells, big.mark = ",", scientific = FALSE),
      format(n_cells, big.mark = ",", scientific = FALSE),
      pct(weighted_pct_gap),
      pct(median_cell_pct_gap)
    )
  ) |>
  pull(line)

type_latest_lines <- type_latest |>
  transmute(
    line = sprintf(
      "| %s | %s | %s | %s | %s |",
      cash_type,
      format(n_cash_type, big.mark = ",", scientific = FALSE),
      format(n_cells, big.mark = ",", scientific = FALSE),
      pct(pct_gap),
      pct(median_cell_pct_gap)
    )
  ) |>
  pull(line)

top_shift_lines <- top_shift |>
  transmute(
    line = sprintf(
      "| %s | %s | %s | %s |",
      state,
      pp(cash_share_shift),
      pp(mortgage_share_shift),
      pp(investor_share_shift)
    )
  ) |>
  pull(line)

type_summary_lines <- type_summary |>
  transmute(
    line = sprintf(
      "| %s | %s | %s | %s |",
      cash_type,
      pct(min_gap),
      pct(max_gap),
      pct(mean_gap)
    )
  ) |>
  pull(line)

report <- c(
  "# Initial Data-Driven Facts: Cash Buyer Premium",
  "",
  "**Date:** 2026-06-05",
  "**Status:** exploratory, not causal.",
  "",
  "## What Ran",
  "",
  "- `01_data_audit.R`: national cash/mortgage/investor flag coverage and monthly shares.",
  "- `02_stylized_facts.R`: time-series tables and plots. FRED mortgage-rate download timed out, so the overlay is missing for this run.",
  "- `03_property_adjusted_scan.R`: cash vs mortgage medians inside county-year-property cells.",
  "- `04_buyer_type_decomposition.R`: same cell comparison split by ordinary, corporate, investor, and distress cash buyers.",
  "",
  "## Empirical Base",
  "",
  sprintf("- CoreLogic audit covers %s valid-price transactions from 2007-2024.", format(total_valid, big.mark = ",", scientific = FALSE)),
  sprintf("- National cash share peaks at %s in %d and bottoms at %s in %d; the 2022 rate shock does not show up as a simple national cash-share jump.", pct(cash_max$cash_share), cash_max$sale_year, pct(cash_min$cash_share), cash_min$sale_year),
  sprintf("- The matched-cell scan covers 185,214 county-year-property cells from 2018-2024. The 2018 matched-cell transaction count is %s; the 2024 count is %s because 2024 is a partial/lower-volume year in the extract.", format(gap_2018$n_transactions_in_cells, big.mark = ","), format(gap_2024$n_transactions_in_cells, big.mark = ",")),
  "",
  "## Fact 1: The Cash Share Shift Is Local, Not Just National",
  "",
  "Largest post-2022 increases in cash share relative to 2019-2021:",
  "",
  "| State | Cash-share shift | Mortgage-share shift | Investor-share shift |",
  "|---|---:|---:|---:|",
  top_shift_lines,
  "",
  "**Interpretation:** this is already more interesting than a national-rate story. Cash shares move sharply in some states, while investor-share shifts are small. The next pass should ask what distinguishes these states: market thinness, rurality, local credit conditions, distress, insurance/climate shocks, or data coverage.",
  "",
  "## Fact 2: The Property-Adjusted Cash Gap Is Large But Narrows Over Time",
  "",
  "| Year | Transactions in matched cells | Cells | Weighted gap | Median-cell gap |",
  "|---|---:|---:|---:|---:|",
  year_gap_lines,
  "",
  sprintf("The transaction-weighted matched-cell gap moves from %s in 2018 to %s in 2024.", pct(gap_2018$weighted_pct_gap), pct(gap_2024$weighted_pct_gap)),
  "",
  "**Interpretation:** a simple 'cash gained bargaining power after rates rose' hypothesis is not supported by this first national scan. The discount is still large, but it does not mechanically widen after 2022.",
  "",
  "## Fact 3: Cash Is Not One Buyer Type",
  "",
  "Latest-year matched-cell gaps by cash-buyer type:",
  "",
  "| Cash type | Cash transactions in cells | Cells | Weighted gap vs mortgage | Median-cell gap |",
  "|---|---:|---:|---:|---:|",
  type_latest_lines,
  "",
  "Gap ranges over 2018-2024:",
  "",
  "| Cash type | Most negative year | Least negative year | Mean gap |",
  "|---|---:|---:|---:|",
  type_summary_lines,
  "",
  "**Interpretation:** the average cash discount is partly a composition object. Ordinary cash buyers are discounted, but investor and distress cash buyers are far more discounted. This creates a cleaner novelty path: decompose the cash discount into financing certainty, institutional-buyer selection, and distress/intermediation.",
  "",
  "## Fact 4: Corporate And Investor Flags Disagree",
  "",
  "In the matched-cell scan, corporate-buyer cash shares are often much larger than `investor_purchase_indicator` cash shares. That suggests CoreLogic's investor flag is not interchangeable with entity-buyer status. This is not a final economic result, but it is a data fact that matters for any investor-buyer paper.",
  "",
  "## Candidate Novel Paper Direction",
  "",
  "**Working title:** The Many Meanings of Cash in Housing Markets.",
  "",
  "**Core empirical claim to test next:** the cash-mortgage price gap is not one premium. It is a mixture of an ordinary-household cash discount, a corporate acquisition discount, an investor-selection discount, and a distress-market discount. The novel contribution would be to show how much of the headline cash discount survives after stripping out institutional and distress channels.",
  "",
  "## Next Analyses",
  "",
  "1. Validate the buyer-type flags: audit weird corporate-indicator values and confirm whether `corporate_buyer` should be stricter than `== 'Y'`.",
  "2. Re-run the type decomposition excluding foreclosure/REO and investor/corporate sales to estimate a clean ordinary-household cash gap.",
  "3. Add repeat-sale controls: compare same-parcel price growth when a parcel transitions between mortgage and cash buyers.",
  "4. Add county-level external data after the CoreLogic facts stabilize: FHFA HPI, ACS income/race, HUD vacancy, and a working mortgage-rate source.",
  "5. Search for reversals: states/counties/property cells where ordinary cash buyers pay a premium rather than a discount.",
  "",
  "## Caution",
  "",
  "These are medians inside matched cells, not causal estimates. They do not yet control for unobserved quality, timing within month, seller distress beyond flags, inspection contingencies, days on market, or listing-channel selection."
)

report_path <- path(project_dir, "quality_reports", "specs", "2026-06-05_initial_cash_buyer_facts.md")
dir_create(path_dir(report_path))
writeLines(report, report_path)
message("Wrote: ", report_path)
