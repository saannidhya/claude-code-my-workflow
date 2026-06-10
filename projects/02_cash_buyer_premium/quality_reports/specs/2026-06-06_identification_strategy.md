# Identification Strategy: The Many Meanings of Cash in Housing Markets

**Date:** 2026-06-06
**Project:** `02_cash_buyer_premium`
**Status:** working design for exploration-to-analysis transition

---

## Empirical Starting Point

The initial CoreLogic scan found that the property-adjusted cash-mortgage gap is not homogeneous. In 2024 matched county-year-property cells, ordinary cash transactions were priced about 9% below mortgage transactions, while corporate cash, distress cash, and investor cash transactions were priced much lower. This motivates a paper about what the cash indicator means economically, rather than a paper that treats cash as a single treatment.

## Closest Literature

1. **Mortgage-cash premium puzzle.** Reher and Valkanov estimate that mortgaged buyers pay an 11% premium relative to cash buyers, larger than a simple representative-seller model implies. Their setting establishes the puzzle but treats much of the premium as a financing-frictions/seller-beliefs object.
2. **Financing risk and search frictions.** Han and Hong show in Los Angeles that cash purchases close faster and receive a 2-3.9% discount. Their mechanism is financing risk interacting with re-listing risk.
3. **Forced-sale discounts.** Campbell, Giglio, and Pathak estimate large foreclosure discounts, so any cash-discount estimate that mixes in foreclosure/REO sales partly loads on distress liquidation.
4. **Investor purchases.** Lee and Wylie document that single-family investors are spatially concentrated and more active in lower-value neighborhoods. This makes buyer composition a first-order issue for cash-price comparisons.

## Core Claim To Test

> The mortgage-cash premium is not one premium. It is a weighted mixture of ordinary household financing certainty, investor selection, corporate acquisition, and distress-market intermediation.

The paper should identify which part of the observed cash discount remains after separating these channels.

## Identification Stack

### 1. Within-Cell Decomposition

Estimate price gaps within narrow cells:

```text
log(price_ict) = cell_ct + ordinary_cash_i + corporate_cash_i
               + investor_cash_i + distress_cash_i + error_ict
```

where `cell_ct` is a county-time-property cell, initially county-year x property type x bedrooms x bathrooms x square-footage bin x age bin. Mortgage transactions are the omitted group.

**Interpretation:** descriptive, not causal. It defines the empirical object and prevents the paper from making an average-cash claim that is really an investor/distress claim.

**Threats:** unobserved property quality, seller motivation, repair needs, listing strategy, and within-cell spatial composition.

**Robustness:** county-month cells where sample size allows; ZIP/census-tract cells in high-coverage states; repeat-sale/property fixed effects.

### 2. Repeat-Sale Intermediation Test

Use parcels observed in consecutive transactions. For each purchase-resale pair:

```text
log(resale_price) - log(purchase_price)
  = buyer_type_at_purchase + holding_period_controls
  + purchase_county x purchase_year FE + resale_year FE + error
```

The first pass reports medians and trimmed means by buyer type. The stronger version subtracts county FHFA HPI growth over the holding period.

**Intermediation hypothesis:** investor/corporate cash buyers buy at unusually low prices and later realize higher abnormal resale returns than ordinary cash buyers. If true, deep investor/corporate discounts are not just seller certainty; they are acquisition/intermediation margins.

**Key identifying assumption:** after conditioning on location-time and observable property bins, excess resale returns capture buyer-type selection/intermediation rather than persistent unobserved quality. This is not fully causal until HPI controls and richer geography are added.

**Threats:** renovations, unobserved quality, endogenous holding period, post-purchase improvements, sales to related parties, and stale/duplicate transfers.

**Robustness:** restrict to 0.5-5 year holds, exclude foreclosure/REO purchases, exclude new construction, winsorize returns, compare same ZIP/month cells, add HPI-adjusted returns.

### 3. Mortgage-Friction Shock Validation

Use the 2022 mortgage-rate shock interacted with pre-shock local mortgage dependence:

```text
outcome_ct = county FE + time FE
           + post_2022 x pre_shock_mortgage_dependence_c + error_ct
```

Outcomes include cash share, ordinary-cash gap, investor/corporate cash share, and property-adjusted gap.

**Validation hypothesis:** when mortgage finance tightens, high-mortgage-dependence markets should see transaction composition move toward cash-capable buyers. The first CoreLogic scan does not support a simple national cash-share jump, so the identifying variation must be local.

**External data:** HMDA mortgage-application/origination flows, FRED `MORTGAGE30US`, FHFA county HPI, HUD USPS vacancy data.

### 4. Distress Absorption Test

Use foreclosure/REO-heavy cells and county-years:

```text
cash_gap_ct = distress_share_ct + investor_cash_share_ct
            + county FE + year FE + error_ct
```

**Distress absorption hypothesis:** the largest cash discounts occur where cash buyers absorb forced-sale or quasi-forced-sale inventory. The ordinary-cash gap should be much smaller after removing distressed transactions.

## Prioritized Next Implementation

1. Implement repeat-sale intermediation scan from CoreLogic OT.
2. Produce buyer-type purchase-resale returns by year, state, and holding period.
3. Add ordinary-only and non-distress restrictions.
4. Add external HPI-adjustment once the CoreLogic-only repeat-sale facts are stable.

## Source Links

- Reher and Valkanov, "The Mortgage-Cash Premium Puzzle": https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3751917
- Han and Hong, "Cash is king? Understanding financing risk in housing markets": https://academic.oup.com/rof/article/28/6/2083/7731503
- Campbell, Giglio, and Pathak, "Forced Sales and House Prices": https://www.aeaweb.org/articles?id=10.1257/aer.101.5.2108
- HMDA data browser: https://ffiec.cfpb.gov/data-browser/
- HUD USPS vacancy data: https://www.huduser.gov/portal/datasets/usps.html
