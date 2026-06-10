# State-HPI-Adjusted Repeat-Sale Benchmark

**Date:** 2026-06-06  
**Script:** `scripts/R/09_repeat_sale_state_hpi_adjusted.R`  
**Status:** completed; diagnostic benchmark, not final abnormal-return design.

## Important Correction

The first repeat-sale script used DuckDB `log()`, which is base 10. The state-HPI script recomputes returns directly from prices using natural logs via DuckDB `ln()`. The repeat-sale return magnitudes in earlier discovery reports are therefore superseded.

The affected scripts have been patched to use `ln()` going forward:

- `03_property_adjusted_scan.R`
- `04_buyer_type_decomposition.R`
- `06_repeat_sale_intermediation.R`
- `09_repeat_sale_state_hpi_adjusted.R`
- `10_clean_cash_gap_decomposition.R`

## Method

For each consecutive same-parcel purchase-resale pair:

```text
realized_ln_return = ln(resale_price) - ln(purchase_price)
state_hpi_ln_growth = ln(state_hpi_resale_year) - ln(state_hpi_purchase_year)
state_hpi_adjusted_annualized_return =
  (realized_ln_return - state_hpi_ln_growth) / holding_years
```

The HPI source is `data/external/fhfa_state_hpi.parquet`, annual FHFA all-transactions HPI by state.

## Outputs Written

- `repeat_sale_hpi_adjusted_pairs.parquet`
- `repeat_sale_hpi_merge_coverage_by_state_year.csv`
- `repeat_sale_hpi_adjusted_by_purchase_type.csv`
- `repeat_sale_hpi_adjusted_by_purchase_year_type.csv`
- `repeat_sale_hpi_adjusted_by_hold_bin.csv`
- `repeat_sale_hpi_adjusted_by_state_type.csv`
- `repeat_sale_raw_vs_hpi_adjusted_by_purchase_type.png`
- `repeat_sale_hpi_adjusted_by_hold_bin.png`

## Main Results

| Purchase type | Pairs | HPI match | Median hold years | Raw annual return | State-HPI-adjusted annual return |
|---|---:|---:|---:|---:|---:|
| Mortgage | 3,174,322 | 100.0% | 2.28 | 17.7% | 7.1% |
| Ordinary cash | 959,665 | 100.0% | 1.92 | 35.7% | 23.4% |
| Corporate cash | 576,165 | 100.0% | 1.16 | 54.6% | 41.0% |
| Investor cash | 102,192 | 100.0% | 0.96 | 86.5% | 73.2% |
| Distress cash | 239,925 | 100.0% | 1.00 | 40.8% | 31.4% |

## Interpretation

State-HPI adjustment does not eliminate the repeat-sale gradient. Investor and corporate cash purchases still have much higher resale returns than mortgage purchases. This supports the intermediation interpretation as a descriptive fact.

## Remaining Publication Gate

Do not call these abnormal returns. State annual HPI is too coarse: it does not adjust for county, ZIP, neighborhood appreciation, renovations, property condition, or holding-period selection. A publication version needs county or ZIP HPI adjustment and fixed-effect models.
