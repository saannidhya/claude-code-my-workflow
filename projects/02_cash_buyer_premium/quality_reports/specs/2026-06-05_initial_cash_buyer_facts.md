# Initial Data-Driven Facts: Cash Buyer Premium

**Date:** 2026-06-05
**Status:** exploratory, not causal.

**Superseded numeric warning, 2026-06-06:** The first repeat-sale and matched-cell discovery scripts used DuckDB `log()`, which is base 10. Later scripts now use natural logs via `ln()`. Use `2026-06-06_clean_cash_gap_decomposition.md` and `2026-06-06_state_hpi_adjusted_repeat_sales.md` for current draft-facing magnitudes.

## What Ran

- `01_data_audit.R`: national cash/mortgage/investor flag coverage and monthly shares.
- `02_stylized_facts.R`: time-series tables and plots. FRED mortgage-rate download timed out, so the overlay is missing for this run.
- `03_property_adjusted_scan.R`: cash vs mortgage medians inside county-year-property cells.
- `04_buyer_type_decomposition.R`: same cell comparison split by ordinary, corporate, investor, and distress cash buyers.

## Empirical Base

- CoreLogic audit covers 87,921,761 valid-price transactions from 2007-2024.
- National cash share peaks at 31.7% in 2010 and bottoms at 19.1% in 2020; the 2022 rate shock does not show up as a simple national cash-share jump.
- The matched-cell scan covers 185,214 county-year-property cells from 2018-2024. The 2018 matched-cell transaction count is 4,449,775; the 2024 count is 2,098,413 because 2024 is a partial/lower-volume year in the extract.

## Fact 1: The Cash Share Shift Is Local, Not Just National

Largest post-2022 increases in cash share relative to 2019-2021:

| State | Cash-share shift | Mortgage-share shift | Investor-share shift |
|---|---:|---:|---:|
| MS | 13.8 pp | 9.6 pp | 1.2 pp |
| WV | 12.4 pp | 4.2 pp | 0.7 pp |
| LA | 7 pp | -2.9 pp | 0.6 pp |
| KY | 7 pp | 0.6 pp | 0.1 pp |
| HI | 6 pp | -5.7 pp | 0.1 pp |
| MO | 5.7 pp | -1.5 pp | 0.2 pp |
| ME | 5.6 pp | -7.3 pp | -0.3 pp |
| NE | 5.4 pp | -2.2 pp | 0 pp |

**Interpretation:** this is already more interesting than a national-rate story. Cash shares move sharply in some states, while investor-share shifts are small. The next pass should ask what distinguishes these states: market thinness, rurality, local credit conditions, distress, insurance/climate shocks, or data coverage.

## Fact 2: The Property-Adjusted Cash Gap Is Large But Narrows Over Time

| Year | Transactions in matched cells | Cells | Weighted gap | Median-cell gap |
|---|---:|---:|---:|---:|
| 2018 | 4,449,775 | 29,183 | -15.4% | -11.6% |
| 2019 | 4,541,481 | 28,414 | -15.7% | -12.2% |
| 2020 | 4,562,093 | 26,675 | -15.1% | -10.8% |
| 2021 | 5,282,553 | 31,083 | -13.1% | -7.5% |
| 2022 | 4,648,332 | 28,718 | -14.0% | -8.9% |
| 2023 | 3,767,736 | 24,884 | -13.9% | -9.7% |
| 2024 | 2,098,413 | 16,257 | -12.6% | -8.3% |

The transaction-weighted matched-cell gap moves from -15.4% in 2018 to -12.6% in 2024.

**Interpretation:** a simple 'cash gained bargaining power after rates rose' hypothesis is not supported by this first national scan. The discount is still large, but it does not mechanically widen after 2022.

## Fact 3: Cash Is Not One Buyer Type

Latest-year matched-cell gaps by cash-buyer type:

| Cash type | Cash transactions in cells | Cells | Weighted gap vs mortgage | Median-cell gap |
|---|---:|---:|---:|---:|
| corporate_cash | 187,475 |  6,989 | -16.3% | -16.5% |
| distress_cash |  19,629 |  1,301 | -24.0% | -27.6% |
| investor_cash |   9,991 |    837 | -30.4% | -30.4% |
| ordinary_cash | 418,678 | 12,205 | -9.1% | -4.3% |

Gap ranges over 2018-2024:

| Cash type | Most negative year | Least negative year | Mean gap |
|---|---:|---:|---:|
| investor_cash | -31.9% | -27.7% | -30.0% |
| distress_cash | -25.7% | -24.0% | -24.8% |
| corporate_cash | -18.2% | -14.8% | -16.8% |
| ordinary_cash | -12.8% | -9.1% | -11.5% |

**Interpretation:** the average cash discount is partly a composition object. Ordinary cash buyers are discounted, but investor and distress cash buyers are far more discounted. This creates a cleaner novelty path: decompose the cash discount into financing certainty, institutional-buyer selection, and distress/intermediation.

## Fact 4: Corporate And Investor Flags Disagree

In the matched-cell scan, corporate-buyer cash shares are often much larger than `investor_purchase_indicator` cash shares. That suggests CoreLogic's investor flag is not interchangeable with entity-buyer status. This is not a final economic result, but it is a data fact that matters for any investor-buyer paper.

## Candidate Novel Paper Direction

**Working title:** The Many Meanings of Cash in Housing Markets.

**Core empirical claim to test next:** the cash-mortgage price gap is not one premium. It is a mixture of an ordinary-household cash discount, a corporate acquisition discount, an investor-selection discount, and a distress-market discount. The novel contribution would be to show how much of the headline cash discount survives after stripping out institutional and distress channels.

## Next Analyses

1. Validate the buyer-type flags: audit weird corporate-indicator values and confirm whether `corporate_buyer` should be stricter than `== 'Y'`.
2. Re-run the type decomposition excluding foreclosure/REO and investor/corporate sales to estimate a clean ordinary-household cash gap.
3. Add repeat-sale controls: compare same-parcel price growth when a parcel transitions between mortgage and cash buyers.
4. Add county-level external data after the CoreLogic facts stabilize: FHFA HPI, ACS income/race, HUD vacancy, and a working mortgage-rate source.
5. Search for reversals: states/counties/property cells where ordinary cash buyers pay a premium rather than a discount.

## Caution

These are medians inside matched cells, not causal estimates. They do not yet control for unobserved quality, timing within month, seller distress beyond flags, inspection contingencies, days on market, or listing-channel selection.
