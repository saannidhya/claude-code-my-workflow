# Clean Cash-Gap Decomposition

**Date:** 2026-06-06  
**Script:** `scripts/R/10_clean_cash_gap_decomposition.R`  
**Status:** completed for coverage-filtered 2018-2024 matched property cells.

## Purpose

The earlier buyer-type decomposition allowed corporate, investor, and distress flags to overlap. This script creates draft-facing estimates with:

1. a canonical mutually exclusive taxonomy, and
2. a sequential cleaning exercise from all cash to clean ordinary cash.

State-years with other-or-unknown finance shares above 5 percent are excluded.

## Outputs Written

- `clean_cash_gap_by_cell_definition.csv`
- `clean_cash_gap_by_year.csv`
- `clean_cash_gap_by_state_year.csv`
- `canonical_cash_type_gap_by_year.csv`
- `canonical_cash_type_gap_by_state_year.csv`
- `clean_cash_gap_by_year.png`
- `canonical_cash_type_gap_by_year.png`

## Canonical 2024 Cash-Type Gaps

| Cash type | Cash transactions | Cells | Weighted gap | Median-cell gap |
|---|---:|---:|---:|---:|
| Corporate cash | 148,915 | 5,530 | -29.2% | -30.2% |
| Distress cash | 18,972 | 1,257 | -46.7% | -52.4% |
| Investor cash | 9,836 | 824 | -56.4% | -56.4% |
| Ordinary cash | 401,098 | 11,728 | -19.7% | -9.3% |

The taxonomy priority is distress, investor, corporate, ordinary. These categories are mutually exclusive.

## 2024 Sequential Cleaning

| Sample definition | Cash transactions | Mortgage transactions | Cells | Weighted gap | Median-cell gap |
|---|---:|---:|---:|---:|---:|
| All cash | 624,312 | 1,394,882 | 15,659 | -26.7% | -17.8% |
| Non-distress cash | 594,016 | 1,345,258 | 15,054 | -25.9% | -16.3% |
| Non-institutional, non-distress | 399,694 | 1,079,300 | 11,537 | -20.2% | -10.1% |
| Clean ordinary | 384,758 | 923,671 | 11,460 | -21.6% | -10.1% |

The strict clean-ordinary comparison excludes distress, investor, corporate, and new-construction transactions for both cash and mortgage observations.

## Interpretation

Cleaning reduces the headline gap but does not eliminate it. That supports two simultaneous claims: the average cash discount is partly composition, and ordinary cash remains discounted in matched cells. The latter should not yet be interpreted as a seller-certainty parameter because unobserved quality, contract terms, and exact neighborhood/time selection remain uncontrolled.
