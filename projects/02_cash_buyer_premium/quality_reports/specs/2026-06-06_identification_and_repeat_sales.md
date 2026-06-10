# Identification and Repeat-Sale Intermediation: First Pass

**Date:** 2026-06-06
**Project:** `02_cash_buyer_premium`
**Status:** exploratory evidence for identification design; superseded by state-HPI-adjusted benchmark where noted, not causal.

**Update, 2026-06-06:** `09_repeat_sale_state_hpi_adjusted.R` recomputes repeat-sale returns from prices using natural logs and subtracts annual state-level FHFA HPI growth. The raw return magnitudes in the first-pass table below were generated before the natural-log correction and should not be used as draft-facing estimates. Current draft-facing repeat-sale estimates are in `2026-06-06_state_hpi_adjusted_repeat_sales.md`.

## Identification Direction

The paper should not identify a single treatment effect of `cash`. The data already show that cash status bundles ordinary household liquidity, investor acquisition, corporate/entity buying, and distress absorption. The identification strategy should therefore decompose the observed mortgage-cash premium into channels before attempting causal claims.

Recommended title:

> **The Many Meanings of Cash in Housing Markets**

## Identification Stack

1. **Within-cell decomposition.** Compare mortgage, ordinary cash, corporate cash, investor cash, and distress cash inside narrow property-location-time cells. This defines the empirical object and prevents the average cash discount from being interpreted as a single mechanism.
2. **Repeat-sale intermediation.** Follow properties from purchase to next resale. If investor/corporate cash buyers acquire at deep discounts and later resell at high returns, the channel is intermediation/asset acquisition rather than merely seller certainty.
3. **Mortgage-friction validation.** Use the 2022 rate shock interacted with pre-shock mortgage dependence to test whether local financing constraints shift composition toward cash-capable buyer types.
4. **Distress absorption.** Test whether the deepest cash gaps are concentrated in foreclosure/REO-heavy cells and whether ordinary-cash gaps shrink after removing distress.

## Repeat-Sale Scan Run

`06_repeat_sale_intermediation.R` built consecutive same-parcel transaction pairs from 2018-2024 CoreLogic OT. It restricts to valid residential transactions, same-parcel resale after purchase, sale prices between $10,000 and $10 million, and holding periods from 0.5 to 6 years.

Purchase-side buyer types are mutually exclusive with this priority: distress cash, investor cash, corporate cash, ordinary cash, mortgage, other/unknown.

## First Repeat-Sale Facts

| Purchase type | Pairs | Median hold years | Median purchase price | Median resale price | Mean annualized return | Median annualized return | Resale to mortgage share |
|---|---:|---:|---:|---:|---:|---:|---:|
| mortgage | 3,174,322 | 2.28 | $250,000 | $330,000 | 7.3% | 4.7% | 79.0% |
| ordinary_cash |   959,665 | 1.92 | $160,000 | $250,000 | 14.2% | 6.5% | 57.9% |
| corporate_cash |   576,165 | 1.16 | $170,000 | $299,900 | 20.9% | 14.6% | 67.0% |
| investor_cash |   102,192 | 0.96 | $104,300 | $209,667 | 31.1% | 25.2% | 71.2% |
| distress_cash |   239,925 | 1 | $105,000 | $172,500 | 16.0% | 12.2% | 61.4% |

## Interpretation

The repeat-sale facts support the intermediation interpretation. Investor cash purchases have the lowest median purchase price, short holding periods, and the highest subsequent annualized resale returns. Corporate cash also has much higher annualized resale returns than mortgage purchases. Ordinary cash sits between mortgage and institutional/distress cash, which is exactly the pattern implied by the many-meanings hypothesis.

A useful reading is:

- **Mortgage purchases** are the baseline owner-occupier/liquid-market benchmark.
- **Ordinary cash** appears to carry a discount, but less extreme than institutional cash.
- **Corporate and investor cash** look like acquisition/intermediation transactions.
- **Distress cash** has deep acquisition discounts, but its return profile is below investor cash, possibly because it includes lower-quality or costly-to-repair inventory.

## Identification Caveats

These returns are not abnormal returns yet. The current benchmark subtracts state-level annual HPI growth, but not county- or ZIP-level HPI growth, renovation investment, property quality changes, or selection into short holding periods. Investor/corporate excess returns could reflect improvements made between purchase and resale. The next credible step is to replace the state-HPI benchmark with county or ZIP HPI growth and then test whether excess returns survive within county-year and holding-period bins.

## Next Analysis Tasks

1. Add FHFA county HPI and compute HPI-adjusted repeat-sale returns.
2. Split investor/corporate repeat sales by resale buyer type: resale to mortgage buyer vs resale to cash buyer.
3. Exclude foreclosure/REO purchases and rerun investor/corporate intermediation.
4. Add holding-period bins and purchase-year x county fixed effects.
5. Build a clean ordinary-household cash sample: no investor flag, no corporate buyer, no distress flags, no new construction.

## Source Anchors

- Reher and Valkanov, "The Mortgage-Cash Premium Puzzle": https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3751917
- Han and Hong, "Cash is king? Understanding financing risk in housing markets": https://academic.oup.com/rof/article/28/6/2083/7731503
- Campbell, Giglio, and Pathak, "Forced Sales and House Prices": https://www.aeaweb.org/articles?id=10.1257/aer.101.5.2108
- HMDA data browser: https://ffiec.cfpb.gov/data-browser/
- HUD USPS vacancy data: https://www.huduser.gov/portal/datasets/usps.html
