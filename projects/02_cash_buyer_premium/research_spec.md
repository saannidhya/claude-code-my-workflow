# Research Spec: Cash Buyer Premium

**Slug:** `cash_buyer_premium`
**Date drafted:** 2026-06-05
**Status:** EXPLORATION

---

## Research Question

> What empirically novel facts about cash purchases, mortgage-financed purchases, investor buyers, and transaction prices can be recovered from national CoreLogic transaction microdata?

The project deliberately starts without a fixed causal claim. The first objective is to use CoreLogic's buyer-finance and buyer-type flags to discover where the cash-mortgage price gap is large, stable, surprising, or concentrated among specific transaction types.

## Why This Matters

Cash purchase status is not only a financing detail. It may proxy for liquidity, bargaining power, investor access, speed, underwriting avoidance, distress-sale selection, or seller certainty. Existing papers estimate average cash discounts or mortgage premia, but CoreLogic allows a broader national scan across geography, time, buyer type, distress status, and property characteristics.

## Discovery Questions

| # | Question | What Would Be Novel? |
|---|---|---|
| D1 | Does the cash-mortgage price gap vary sharply across time, especially around the 2022 mortgage-rate shock? | A state- or county-level map of when cash becomes more valuable as mortgage finance tightens |
| D2 | Is the raw cash discount mostly an investor/corporate/distress phenomenon? | Evidence that the average "cash discount" is not about cash itself but about who cash buyers are |
| D3 | Within narrow county-year-property cells, where do cash buyers pay more rather than less? | A reversal would point to competition, urgency, or investor inventory targeting rather than simple liquidity discounts |
| D4 | Do cash shares rise first in low-price segments or distressed markets? | A buyer-composition channel for affordability and market access |
| D5 | Are cash-buyer facts stronger in repeat-sale/liquid parcels than in one-off thin-market parcels? | Separation between bargaining power and property-quality selection |

## Data Requirements

| Source | Variables | Coverage | Notes |
|---|---|---|---|
| CoreLogic OT | sale amount/date, cash flag, mortgage flag, investor flag, corporate buyer flags, foreclosure/REO flags, parcel ID, county/state | National, nominally 2007-2024 for modern analysis | Primary transaction source |
| CoreLogic Prop | structure type, bedrooms, bathrooms, square footage, year built, lot size, property location | National property snapshot | Used for property-adjusted cell comparisons |
| FRED `MORTGAGE30US` | weekly 30-year fixed mortgage rate | National weekly | External macro finance series |
| Optional next stage | FHFA HPI, ACS, HUD USPS vacancy, FEMA disasters | County/ZIP/tract depending source | Add after first CoreLogic-only facts identify promising margins |

## Empirical Strategy For Discovery

1. Audit field coverage by state-year before trusting any cash/mortgage fact.
2. Produce monthly and annual time-series for cash share, mortgage share, investor share, corporate-buyer share, and distress share.
3. Compare raw cash and mortgage median prices by state, year, price tier, and buyer type.
4. Build narrow property cells: county-year x property type x bedrooms x bathrooms x square-footage bin x age bin.
5. Within each cell, compare median log prices for cash and mortgage transactions when both groups have enough observations.
6. Rank cells, counties, states, and years by where the cash-mortgage gap is largest, smallest, or reverses sign.

## Outputs Plan

- **T1:** State-year flag coverage audit
- **T2:** National annual buyer-finance shares
- **T3:** Buyer-type decomposition of cash transactions
- **T4:** Property-adjusted cash-mortgage gaps by year and state
- **F1:** Cash and mortgage shares over time with 30-year mortgage-rate overlay
- **F2:** Cash-mortgage raw median price gap over time
- **F3:** Distribution of property-adjusted cell-level gaps
- **F4:** State heatmap or ranked bars of post-2022 gap changes

## Open Questions

- Are `cash_purchase_indicator` and `mortgage_purchase_indicator` mutually exclusive and consistently populated after 2007?
- Does corporate-buyer status add information beyond the CoreLogic investor flag?
- Which geography has enough coverage for a credible second-stage causal design: county, ZIP, tract, or state?
- Does a future theory center on financing constraints, investor market power, seller certainty, or distress-market selection?
