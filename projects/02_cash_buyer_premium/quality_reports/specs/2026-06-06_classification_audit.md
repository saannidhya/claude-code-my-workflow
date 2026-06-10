# Classification Audit: Finance and Buyer-Type Flags

**Date:** 2026-06-06  
**Script:** `scripts/R/08_classification_audit.R`  
**Status:** completed for the 2018-2024 valid-price residential analysis window.

## Why This Matters

The paper's identification strategy starts from a measurement claim: cash is not one economic category. That claim is only credible if the finance flags and buyer-type flags are audited before they become regression indicators.

## Outputs Written

- `classification_overlap_national_year.csv`
- `classification_overlap_state_year.csv`
- `finance_flag_crosswalk_state_year.csv`
- `unknown_finance_share_state_year.csv`
- `buyer_taxonomy_national_year.csv`
- `cash_overlap_national_year.csv`

## 2024 National Buyer Taxonomy

| Assigned category | Transactions | Share |
|---|---:|---:|
| Mortgage | 1,845,337 | 68.8% |
| Ordinary cash | 532,230 | 19.8% |
| Corporate cash | 208,581 | 7.8% |
| Distress cash | 37,528 | 1.4% |
| Investor cash | 23,825 | 0.9% |
| Noncash/nonmortgage unknown | 35,109 | 1.3% |

The residual category is small nationally in 2024, but it is not ignorable by geography.

## State Coverage Warning

Highest 2024 other-or-unknown finance shares:

| State | Transactions | Other/unknown finance share |
|---|---:|---:|
| VT | 6,433 | 100.0% |
| SD | 840 | 40.2% |
| WI | 50,324 | 11.4% |
| MN | 50,563 | 8.9% |
| NY | 85,100 | 3.6% |
| WV | 11,324 | 3.5% |
| MI | 81,132 | 3.3% |
| IN | 50,707 | 2.2% |

The main draft should avoid interpreting state-level results without coverage filters. Vermont is unusable for 2024 finance-status analysis in this extract.

## 2024 Cash-Flag Overlap

Among cash transactions:

| Investor | Corporate | Distress | Cash transactions | Median sale price |
|---:|---:|---:|---:|---:|
| 0 | 0 | 0 | 532,230 | 292,000 |
| 0 | 0 | 1 | 8,962 | 108,000 |
| 0 | 1 | 0 | 208,581 | 240,000 |
| 0 | 1 | 1 | 28,566 | 140,638 |
| 1 | 0 | 0 | 8,907 | 91,100 |
| 1 | 1 | 0 | 14,918 | 130,000 |

This confirms the classification issue: corporate, investor, and distress flags overlap materially. In 2024, most investor-flagged cash transactions are also corporate-flagged, and most distress-cash transactions are corporate-flagged. The paper should keep the mutually exclusive priority taxonomy for main tables and use overlap tables in the appendix.

## Identification Implication

The classification audit strengthens the "many meanings" framing but also imposes a constraint: the paper must report coverage filters and overlap diagnostics before making claims about investor or corporate cash. The next empirical step is a clean ordinary-cash gap that excludes corporate, investor, distress, new construction, and any problematic finance-status states.
