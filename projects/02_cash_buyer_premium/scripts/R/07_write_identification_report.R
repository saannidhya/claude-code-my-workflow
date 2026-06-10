#' 07: Write identification and repeat-sale intermediation report.

source(here::here("projects/02_cash_buyer_premium/scripts/R/00_setup.R"))

pct <- function(x, accuracy = 0.1) scales::percent(x, accuracy = accuracy)
dollar <- function(x) scales::dollar(x, accuracy = 1, big.mark = ",")

repeat_summary <- readr::read_csv(
  path(tables_dir, "repeat_sale_returns_by_purchase_type.csv"),
  show_col_types = FALSE
)

type_lines <- repeat_summary |>
  mutate(
    mean_ann_pct = exp(mean_annualized_log_return_w) - 1,
    median_ann_pct = exp(median_annualized_log_return) - 1
  ) |>
  transmute(
    line = sprintf(
      "| %s | %s | %s | %s | %s | %s | %s | %s |",
      purchase_type,
      format(n_pairs, big.mark = ",", scientific = FALSE),
      round(median_hold_years, 2),
      dollar(median_purchase_price),
      dollar(median_resale_price),
      pct(mean_ann_pct),
      pct(median_ann_pct),
      pct(resale_mortgage_share)
    )
  ) |>
  pull(line)

report <- c(
  "# Identification and Repeat-Sale Intermediation: First Pass",
  "",
  "**Date:** 2026-06-06",
  "**Project:** `02_cash_buyer_premium`",
  "**Status:** exploratory evidence for identification design; not HPI-adjusted and not causal.",
  "",
  "## Identification Direction",
  "",
  "The paper should not identify a single treatment effect of `cash`. The data already show that cash status bundles ordinary household liquidity, investor acquisition, corporate/entity buying, and distress absorption. The identification strategy should therefore decompose the observed mortgage-cash premium into channels before attempting causal claims.",
  "",
  "Recommended title:",
  "",
  "> **The Many Meanings of Cash in Housing Markets**",
  "",
  "## Identification Stack",
  "",
  "1. **Within-cell decomposition.** Compare mortgage, ordinary cash, corporate cash, investor cash, and distress cash inside narrow property-location-time cells. This defines the empirical object and prevents the average cash discount from being interpreted as a single mechanism.",
  "2. **Repeat-sale intermediation.** Follow properties from purchase to next resale. If investor/corporate cash buyers acquire at deep discounts and later resell at high returns, the channel is intermediation/asset acquisition rather than merely seller certainty.",
  "3. **Mortgage-friction validation.** Use the 2022 rate shock interacted with pre-shock mortgage dependence to test whether local financing constraints shift composition toward cash-capable buyer types.",
  "4. **Distress absorption.** Test whether the deepest cash gaps are concentrated in foreclosure/REO-heavy cells and whether ordinary-cash gaps shrink after removing distress.",
  "",
  "## Repeat-Sale Scan Run",
  "",
  "`06_repeat_sale_intermediation.R` built consecutive same-parcel transaction pairs from 2018-2024 CoreLogic OT. It restricts to valid residential transactions, same-parcel resale after purchase, sale prices between $10,000 and $10 million, and holding periods from 0.5 to 6 years.",
  "",
  "Purchase-side buyer types are mutually exclusive with this priority: distress cash, investor cash, corporate cash, ordinary cash, mortgage, other/unknown.",
  "",
  "## First Repeat-Sale Facts",
  "",
  "| Purchase type | Pairs | Median hold years | Median purchase price | Median resale price | Mean annualized return | Median annualized return | Resale to mortgage share |",
  "|---|---:|---:|---:|---:|---:|---:|---:|",
  type_lines,
  "",
  "## Interpretation",
  "",
  "The repeat-sale facts support the intermediation interpretation. Investor cash purchases have the lowest median purchase price, short holding periods, and the highest subsequent annualized resale returns. Corporate cash also has much higher annualized resale returns than mortgage purchases. Ordinary cash sits between mortgage and institutional/distress cash, which is exactly the pattern implied by the many-meanings hypothesis.",
  "",
  "A useful reading is:",
  "",
  "- **Mortgage purchases** are the baseline owner-occupier/liquid-market benchmark.",
  "- **Ordinary cash** appears to carry a discount, but less extreme than institutional cash.",
  "- **Corporate and investor cash** look like acquisition/intermediation transactions.",
  "- **Distress cash** has deep acquisition discounts, but its return profile is below investor cash, possibly because it includes lower-quality or costly-to-repair inventory.",
  "",
  "## Identification Caveats",
  "",
  "These returns are not abnormal returns yet. They are not adjusted for county-level HPI growth, renovation investment, property quality changes, or selection into short holding periods. Investor/corporate excess returns could reflect improvements made between purchase and resale. The next credible step is to subtract local HPI growth and then test whether excess returns survive within county-year and holding-period bins.",
  "",
  "## Next Analysis Tasks",
  "",
  "1. Add FHFA county HPI and compute HPI-adjusted repeat-sale returns.",
  "2. Split investor/corporate repeat sales by resale buyer type: resale to mortgage buyer vs resale to cash buyer.",
  "3. Exclude foreclosure/REO purchases and rerun investor/corporate intermediation.",
  "4. Add holding-period bins and purchase-year x county fixed effects.",
  "5. Build a clean ordinary-household cash sample: no investor flag, no corporate buyer, no distress flags, no new construction.",
  "",
  "## Source Anchors",
  "",
  "- Reher and Valkanov, \"The Mortgage-Cash Premium Puzzle\": https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3751917",
  "- Han and Hong, \"Cash is king? Understanding financing risk in housing markets\": https://academic.oup.com/rof/article/28/6/2083/7731503",
  "- Campbell, Giglio, and Pathak, \"Forced Sales and House Prices\": https://www.aeaweb.org/articles?id=10.1257/aer.101.5.2108",
  "- HMDA data browser: https://ffiec.cfpb.gov/data-browser/",
  "- HUD USPS vacancy data: https://www.huduser.gov/portal/datasets/usps.html"
)

report_path <- path(project_dir, "quality_reports", "specs", "2026-06-06_identification_and_repeat_sales.md")
dir_create(path_dir(report_path))
writeLines(report, report_path)
message("Wrote: ", report_path)
