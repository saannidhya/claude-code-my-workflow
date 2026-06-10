# Manuscript Architecture Memo: The Many Meanings of Cash in Housing Markets

**Date:** 2026-06-06  
**Agent:** C  
**Project:** `projects/02_cash_buyer_premium`  
**Write scope:** architecture memo only; no manuscript drafting or script changes.

## Purpose

This memo proposes a publication-ready architecture for a paper titled **"The Many Meanings of Cash in Housing Markets."** It is based only on the current project reports in `quality_reports/specs`. The memo is strict about evidentiary status: current CoreLogic facts motivate the paper, but the paper should not yet claim causal estimates, abnormal returns, or definitive mechanisms.

## Current Evidentiary Base

### Can be said now

The current reports support these descriptive statements:

1. The CoreLogic audit covers 87,921,761 valid-price transactions from 2007-2024.
2. National cash share peaked at 31.7 percent in 2010 and bottomed at 19.1 percent in 2020.
3. The 2022 mortgage-rate shock does not appear as a simple national jump in cash share.
4. Post-2022 cash-share changes are local: several states show sizable increases relative to 2019-2021 while investor-share shifts are small.
5. In matched county-year-property cells from 2018-2024, cash transactions sell below mortgage transactions, but the gap narrows rather than widens mechanically after 2022.
6. The 2024 matched-cell weighted cash-mortgage gap is about -12.6 percent overall.
7. Cash is heterogeneous. In 2024 matched cells, ordinary cash is much less discounted than corporate cash, distress cash, and investor cash.
8. Repeat-sale first-pass facts show investor and corporate cash purchases have lower acquisition prices, shorter holding periods, and much higher subsequent annualized resale returns than mortgage purchases.
9. CoreLogic corporate-buyer and investor-purchase flags are not interchangeable; this is a data contribution and a warning for empirical interpretation.

### Can be used as motivation but not final evidence

The current reports motivate, but do not yet establish, these claims:

1. Investor and corporate cash buyers earn abnormal resale returns.
2. Cash discounts reflect intermediation margins rather than only seller financing-risk discounts.
3. Distress absorption explains the deepest cash discounts.
4. Ordinary household cash carries a smaller financing-certainty discount after excluding institutional and distress channels.
5. Local mortgage frictions after 2022 shifted composition toward cash-capable buyer types.

### Should not be claimed yet

The paper should not yet claim:

1. A causal effect of cash financing on price.
2. A causal effect of the 2022 rate shock on cash-buyer composition.
3. Investor/corporate abnormal returns net of local HPI growth, renovations, and holding-period selection.
4. Welfare effects for sellers, borrowers, or neighborhoods.
5. A final decomposition of the mortgage-cash premium into exact contribution shares.

## Abstract Logic

The abstract should be built around a puzzle, a decomposition, and a disciplined empirical payoff.

1. **Puzzle:** Housing-market studies often treat cash purchases as a single financing category, but cash status bundles several economic objects: household liquidity, financing certainty, institutional acquisition, investor selection, and distress absorption.
2. **Data and measurement:** Use national CoreLogic transaction data to classify cash purchases into ordinary, corporate, investor, and distress categories, then compare them to mortgage-financed transactions within narrow property-location-time cells.
3. **Main descriptive finding:** The headline cash discount masks strong heterogeneity. Ordinary cash buyers transact below mortgage buyers, but corporate, investor, and distress cash purchases account for much deeper discounts.
4. **Dynamic/intermediation finding:** Repeat-sale evidence shows investor and corporate cash buyers acquire at low prices and resell after short holding periods at much higher raw annualized returns than mortgage buyers.
5. **Interpretation with caution:** These patterns imply that the mortgage-cash premium is not one premium. A publication version should quantify how much of the observed gap reflects ordinary financing certainty versus institutional/distress intermediation, with causal claims reserved for HPI-adjusted and robustness-tested specifications.

Do not open the abstract with the 2022 rate shock. The current evidence says the national rate-shock story is too simple. The rate shock belongs as a validation exercise, not the central pitch.

## Introduction Arc

### Paragraph 1: Why cash matters

Start from a familiar housing-market fact: sellers, brokers, and researchers distinguish cash offers from mortgaged offers because financing affects execution risk, speed, and bargaining. The literature has treated this as a mortgage-cash premium or a cash discount puzzle.

### Paragraph 2: The identification problem

Introduce the central critique: "cash" is not only a financing condition. In transaction data, it also identifies buyer type, seller distress, acquisition strategy, local credit conditions, and property selection. A single cash coefficient therefore mixes mechanisms.

### Paragraph 3: Data advantage

State that CoreLogic allows national transaction-level measurement of financing status, buyer-type indicators, corporate/entity status, distress indicators, and same-parcel repeat sales. The paper uses that breadth to split the cash category before interpreting price gaps.

### Paragraph 4: First fact, national time series

Show that cash shares vary over time, but the 2022 rate shock does not generate a simple national cash-share jump. This motivates a local and compositional approach rather than a one-factor national story.

### Paragraph 5: Second fact, within-cell cash gaps

Report that matched county-year-property comparisons show a large cash discount, but this average gap differs sharply by buyer type. Ordinary cash is discounted less than corporate, investor, and distress cash.

### Paragraph 6: Third fact, repeat-sale dynamics

Introduce the same-parcel repeat-sale evidence: investor and corporate cash purchases are followed by short holding periods and high raw annualized resale returns. Frame this as evidence that some cash transactions are acquisition/intermediation events.

### Paragraph 7: Contribution and restraint

State the paper's main contribution: it decomposes the mortgage-cash premium into economically distinct channels. Be explicit that the strongest current evidence is descriptive and that the publication version will use HPI-adjusted repeat-sale returns, non-distress samples, and local shock validation before making mechanism claims.

## Contribution Claims

### Claim 1: Measurement contribution

**Can say now:** The paper shows that cash is an empirically heterogeneous category in national housing transaction data. Corporate-buyer status, investor-purchase flags, distress indicators, and ordinary cash purchases produce different price patterns.

**Needs more analysis:** A final publication claim should quantify how much each cash type contributes to the aggregate cash-mortgage gap over time and across markets.

### Claim 2: Reinterpretation of the mortgage-cash premium

**Can say now:** The average cash discount is partly a composition object. Treating cash as one coefficient risks conflating financing certainty with institutional acquisition and distress-market activity.

**Needs more analysis:** The final paper should estimate the ordinary-household cash gap after excluding investor, corporate, distress, foreclosure/REO, related-party, and new-construction transactions.

### Claim 3: Intermediation channel

**Can say now:** Raw repeat-sale patterns are consistent with an intermediation channel: investor and corporate cash buyers acquire at lower prices, hold for shorter periods, and resell at higher raw annualized returns.

**Needs more analysis:** This cannot be called abnormal return or value creation until returns are adjusted for FHFA county HPI growth, holding-period selection, renovation or quality change proxies, and local purchase-year conditions.

### Claim 4: Local mortgage-friction validation

**Can say now:** The national cash-share series does not support a simple post-2022 cash boom narrative. Cross-state shifts suggest local variation matters.

**Needs more analysis:** The rate-shock design needs pre-shock mortgage dependence, HMDA flows, local HPI controls, and county and time fixed effects before it can validate a financing-friction mechanism.

### Claim 5: Data warning for investor-buyer research

**Can say now:** CoreLogic corporate-buyer and investor-purchase indicators disagree enough that they should be treated as distinct measures.

**Needs more analysis:** The final paper should audit these flags, document coding rules, and show robustness to alternative definitions.

## Proposed Section Outline

### 1. Introduction

Purpose: Frame the paper around the mistake of treating cash as a single economic object. Preview the decomposition and repeat-sale evidence. End with clearly bounded contributions.

Key evidence to include:

- National cash share over 2007-2024.
- Matched-cell average cash gap over 2018-2024.
- 2024 heterogeneity by ordinary, corporate, investor, and distress cash.
- Repeat-sale raw return gradient by purchase type.

### 2. Institutional Background and Literature

Purpose: Explain why cash offers can receive discounts and why the same indicator may also capture selection.

Subsections:

1. Financing risk and seller execution risk.
2. Forced sales and distress discounts.
3. Investor and corporate single-family acquisition.
4. Why national transaction data can separate these channels.

Positioning:

- Reher and Valkanov establish the mortgage-cash premium puzzle.
- Han and Hong establish financing-risk/search-friction mechanisms.
- Campbell, Giglio, and Pathak establish forced-sale discounts.
- Investor-purchase work motivates buyer-composition concerns.

Do not overclaim novelty as discovering that cash buyers get discounts. The novelty is decomposing the cash indicator and showing that different cash meanings have different price and resale patterns at national scale.

### 3. Data and Classification

Purpose: Define the empirical sample and the buyer-type taxonomy.

Core elements:

- CoreLogic residential transaction sample, valid-price restrictions, 2007-2024 audit sample.
- Matched-cell sample for 2018-2024.
- Repeat-sale pair construction: same parcel, consecutive transactions, 0.5-6 year holding periods, sale prices from $10,000 to $10 million.
- Buyer-type hierarchy: distress cash, investor cash, corporate cash, ordinary cash, mortgage, other/unknown.
- Explanation that hierarchy is necessary because categories overlap.

Required caution:

- Corporate and investor flags should be audited before final publication.
- 2024 is partial/lower-volume in the current extract and should not be interpreted as a full-year market fact unless coverage is verified.

### 4. Descriptive Facts: Cash Is Local and Heterogeneous

Purpose: Establish the descriptive base.

Subsections:

1. National cash and mortgage shares over time.
2. Post-2022 state-level cash-share shifts.
3. Property-adjusted cash-mortgage gaps by year.
4. Buyer-type decomposition of cash gaps.

Main message:

The cash-mortgage gap is large, but its interpretation changes once cash is split into ordinary, corporate, investor, and distress categories.

### 5. Within-Cell Decomposition

Purpose: Turn descriptive comparisons into a regression framework.

Preferred baseline:

```text
log(price_i) = cell_cpt + ordinary_cash_i + corporate_cash_i
             + investor_cash_i + distress_cash_i + controls_i + error_i
```

where cells combine geography, time, and property bins. Mortgage transactions are the omitted group.

Publication version should report:

- Baseline coefficients by cash type.
- Year-by-year estimates.
- State or market-type heterogeneity.
- Composition accounting: contribution of each cash type to the aggregate cash discount.

Interpretation:

This is descriptive unless strengthened with repeat-sale or property fixed-effect variants. It should be presented as decomposition, not causal identification.

### 6. Repeat-Sale Intermediation

Purpose: Test whether deep cash discounts look like acquisition/intermediation events.

Baseline logic:

```text
log(resale_price) - log(purchase_price)
  = buyer_type_at_purchase + holding_period_controls
  + purchase_county x purchase_year FE + resale_year FE + error
```

Preferred publication outcome:

- HPI-adjusted annualized return over the holding period.
- Separate raw, HPI-adjusted, and within-county-year results.
- Holding-period bins.
- Exclusions for foreclosure/REO, new construction, investor/corporate overlap, and likely non-arm's-length transfers where possible.

Current status:

The raw facts are promising but not sufficient. This section should not be finalized until HPI adjustment is complete.

### 7. Mortgage-Friction Validation

Purpose: Connect the decomposition back to financing risk without letting the 2022 shock dominate the paper.

Suggested design:

```text
outcome_ct = county FE + time FE
           + post_2022_t x pre_shock_mortgage_dependence_c + error_ct
```

Outcomes:

- Cash share.
- Ordinary cash share.
- Investor/corporate cash share.
- Ordinary-cash gap.
- Institutional/distress cash gap.
- Aggregate property-adjusted cash gap.

Role in paper:

Validation, not the central identification. If financing constraints matter, high pre-shock mortgage-dependence markets should show more compositional movement after rates rise.

### 8. Distress Absorption and Robustness

Purpose: Separate forced-sale or quasi-forced-sale discounts from ordinary cash financing effects.

Analyses:

- Estimate gaps excluding foreclosure/REO and distress flags.
- Estimate gaps in high- versus low-distress county-years.
- Test whether investor/corporate gaps shrink when distress is excluded.
- Compare ordinary cash gaps in non-distress arms-length samples.

Publication payoff:

This section is crucial for making the title credible. "Many meanings" requires showing that distress and intermediation are not just labels but empirically meaningful channels.

### 9. Discussion and Conclusion

Purpose: Reinterpret the mortgage-cash premium.

Conclusion should say:

- Cash transactions combine household liquidity, financing certainty, institutional acquisition, investor selection, and distress absorption.
- The average cash discount is not a structural parameter.
- Policy or market interpretations of cash-buyer activity should distinguish ordinary households from institutional and distress channels.

Conclusion should not say:

- Cash buyers exploit sellers in general.
- Investors earn abnormal returns without HPI-adjusted evidence.
- Mortgage borrowers always overpay causally.

## Table and Figure Sequence

### Main figures

**Figure 1: National transaction composition, 2007-2024**  
Lines for cash share, mortgage share, and investor share. Annotate 2010 peak, 2020 trough, and 2022 rate-shock period. Purpose: show why the paper cannot rely on a simple national post-2022 cash-boom story.

**Figure 2: State-level post-2022 cash-share shifts**  
Map or ranked dot plot of changes relative to 2019-2021. Include investor-share shifts as a comparison. Purpose: move the story from national averages to local composition.

**Figure 3: Matched-cell cash-mortgage gap by year, 2018-2024**  
Plot weighted and median-cell gaps. Purpose: show a persistent cash discount that narrows rather than mechanically widens after 2022.

**Figure 4: 2024 matched-cell gap by cash type**  
Coefficient or bar plot for ordinary, corporate, investor, and distress cash. Purpose: the core "many meanings" figure.

**Figure 5: Repeat-sale raw annualized returns by purchase type**  
Show mean and median annualized returns, with holding-period medians. Purpose: motivate intermediation. Label as raw/unadjusted in the title.

**Figure 6: HPI-adjusted repeat-sale returns by purchase type**  
This is missing. It should become the paper's dynamic evidence figure once available.

### Main tables

**Table 1: Sample construction and transaction counts**  
Rows for national audit sample, matched-cell sample, buyer-type decomposition sample, and repeat-sale sample. Include years, restrictions, transactions, cells or pairs.

**Table 2: Buyer-type taxonomy and overlap audit**  
Show financing status, corporate flag, investor flag, distress flag, and assigned mutually exclusive category. Include overlap counts. This table is essential because the paper's contribution depends on classification credibility.

**Table 3: Within-cell price gaps by buyer type**  
Regression table with mortgage omitted. Columns should add controls/cells: county-year-property bins, county-month bins where possible, ZIP/tract robustness in high-coverage places, non-distress restrictions.

**Table 4: Composition accounting of aggregate cash discount**  
Decompose the aggregate cash-mortgage gap into ordinary, corporate, investor, and distress components. This table is missing and should be built before drafting final results.

**Table 5: Repeat-sale returns by purchase type**  
Raw first, then HPI-adjusted. Include holding-period controls and purchase county-year fixed effects in later columns.

**Table 6: 2022 mortgage-friction validation**  
Post-2022 by pre-shock mortgage dependence effects on composition and gaps. This is not yet available.

**Table 7: Distress and ordinary-cash robustness**  
Show how ordinary-cash gaps change after excluding distress, corporate, investor, new construction, and other problematic transaction types.

## Appendix Plan

### Appendix A: Data construction

- CoreLogic sample restrictions.
- Price bounds.
- Valid residential transaction definitions.
- Missing financing-status handling.
- 2024 coverage warning.

### Appendix B: Buyer-type classification

- Exact variable definitions.
- Priority ordering.
- Corporate/investor flag disagreement.
- Overlap matrix.
- Alternative classifications.

### Appendix C: Matched-cell construction

- Geography-time-property cell definitions.
- Minimum cell-size requirements.
- Square-footage and age bins.
- County-year versus county-month and ZIP/tract alternatives.

### Appendix D: Additional descriptive facts

- State-by-year cash shares.
- State-by-year investor/corporate cash shares.
- Distribution of matched-cell gaps.
- Counties or states where ordinary cash pays a premium rather than a discount.

### Appendix E: Repeat-sale construction

- Parcel-linking logic.
- Consecutive-sale restrictions.
- Holding-period restrictions.
- Treatment of flips, duplicate transfers, related-party transactions if available.
- Return winsorization and trimming.

### Appendix F: HPI adjustment

- FHFA county HPI merge.
- Handling counties without HPI.
- Interpolation rules.
- HPI-adjusted return formulas.

### Appendix G: Mortgage-friction validation

- HMDA mortgage-dependence measure.
- Rate-shock timing.
- Alternative pre-periods.
- County and time fixed-effect specifications.

### Appendix H: Distress robustness

- Foreclosure/REO definitions.
- Exclusions by distress category.
- High-distress market splits.
- Ordinary-cash clean sample.

### Appendix I: Literature and external validity

- Comparison to Reher and Valkanov estimates.
- Comparison to Han and Hong's LA financing-risk estimates.
- Relation to forced-sale discounts.
- Relation to investor-purchase concentration.

## Evidence Still Missing

### Highest priority before paper drafting

1. **HPI-adjusted repeat-sale returns.** Raw investor/corporate returns are not enough for a publication claim.
2. **Clean ordinary-cash sample.** Exclude corporate, investor, distress, foreclosure/REO, new construction, and likely non-arm's-length transfers where possible.
3. **Buyer-flag audit.** Document corporate-buyer and investor-purchase coding, overlap, and odd values.
4. **Composition accounting.** Quantify how much of the headline cash gap comes from category shares versus within-category discounts.
5. **County-month or finer-cell robustness.** County-year cells are a useful first pass but may leave within-county timing and neighborhood quality concerns.

### Second priority

1. **External mortgage-friction data.** HMDA and FRED/FHFA links are needed for the 2022 validation design.
2. **Distress intensity measures.** The distress channel needs market-level and transaction-level validation.
3. **Heterogeneity by market type.** Rurality, liquidity, price tier, investor-intensity, and state-level coverage may explain post-2022 local shifts.
4. **Reversal search.** Identify markets or cells where ordinary cash pays a premium; these cases can discipline the mechanism.
5. **Resale buyer type.** Investor/corporate cash resales to mortgage buyers may be especially informative about intermediation.

### Optional but valuable

1. Renovation or improvement proxies if available in CoreLogic or linked data.
2. Days-on-market or listing-channel data if available.
3. Appraisal or assessed-value benchmarks to separate quality from bargaining.
4. Neighborhood demographic controls from ACS for heterogeneity and external validity.

## Recommended Manuscript Discipline

The paper should be written as a decomposition and interpretation paper first. The safest high-level sentence is:

> The mortgage-cash price gap is not one object; it is a composite of ordinary household liquidity, institutional acquisition, investor selection, and distress absorption.

The paper should avoid the stronger sentence until further analysis is complete:

> Cash investors earn abnormal returns because they exploit financing-constrained sellers.

That stronger claim requires HPI-adjusted repeat-sale evidence, distress exclusions, holding-period controls, and some way to address renovations or unobserved quality change.

## Proposed One-Sentence Contribution

Using national CoreLogic transaction data, the paper shows that the apparent mortgage-cash premium is a composite object: ordinary cash, corporate cash, investor cash, and distress cash carry sharply different price gaps and resale dynamics, implying that empirical and policy interpretations of cash buying must distinguish financing certainty from acquisition and distress intermediation.

