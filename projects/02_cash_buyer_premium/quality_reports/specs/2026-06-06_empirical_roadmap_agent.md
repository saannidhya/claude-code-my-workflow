# Empirical Roadmap Review: The Many Meanings of Cash in Housing Markets

**Date:** 2026-06-06  
**Agent:** B  
**Scope:** empirical credibility review of `projects/02_cash_buyer_premium` scripts and generated outputs.  
**Constraint:** no script changes and no heavy national reruns.

## Bottom Line

This project has a promising descriptive core: the cash-mortgage price gap is large, persistent, and sharply heterogeneous by cash-buyer type. The best current evidence supports the proposed title, **"The Many Meanings of Cash in Housing Markets,"** because cash status bundles ordinary household liquidity, corporate/entity acquisition, investor acquisition, and distress absorption.

It is not yet publication-ready. The main gap is that the current tables establish patterns, not credible mechanisms. The next stage should turn the discovery scans into a small set of audited, interpretable, and robustness-tested empirical objects: clean ordinary cash, clean institutional cash, distress-excluded gaps, HPI-adjusted repeat-sale returns, and local mortgage-friction validation.

## Strongest Current Empirical Facts

1. **The national cash-share story is not a simple 2022 rate-shock story.**  
   `01_data_audit.R` and `02_stylized_facts.R` cover 87,921,761 valid-price residential transactions from 2007-2024. Cash share peaks at 31.7% in 2010, bottoms at 19.1% in 2020, and is 22.4% in 2024. There is no national post-2022 cash-share surge.

2. **Post-2022 cash-share shifts are local.**  
   `state_post_2022_finance_shift.csv` shows large increases in states such as MS (+13.8 pp), WV (+12.4 pp), LA (+7.0 pp), KY (+7.0 pp), and HI (+6.0 pp). Investor-share shifts in those same comparisons are small, so the local cash-share changes are not obviously reducible to the CoreLogic investor flag.

3. **The property-adjusted cash discount is large but narrows after 2020.**  
   `03_property_adjusted_scan.R` compares cash and mortgage median log prices inside county-year-property cells from 2018-2024. The matched-cell scan covers 185,214 cells. The transaction-weighted gap moves from -15.4% in 2018 to -12.6% in 2024; the median-cell gap moves from -11.6% to -8.3%.

4. **Cash is not one buyer type.**  
   `04_buyer_type_decomposition.R` shows 2024 matched-cell gaps of -9.1% for ordinary cash, -16.3% for corporate cash, -24.0% for distress cash, and -30.4% for investor cash. This is the most publishable current fact because it directly motivates the paper's framing.

5. **Corporate/entity and investor flags are not interchangeable.**  
   The matched-cell cash sample has corporate-buyer shares around 31.7%-36.6% from 2018-2024, while the investor share is only about 1.8%-4.8%. `buyer_type_year.csv` also shows large `cash_corporate_not_investor` counts. This classification disagreement should become a data-construction result, not just a caveat.

6. **Repeat-sale facts support an intermediation interpretation.**  
   `06_repeat_sale_intermediation.R` builds 5,196,686 consecutive same-parcel pairs from 2018-2024 with 0.5-6 year holds. Mean annualized repeat-sale returns are 7.3% for mortgage purchases, 14.2% for ordinary cash, 20.9% for corporate cash, 31.1% for investor cash, and 16.0% for distress cash. Investor cash has the lowest median purchase price ($104,300), short median holds (0.96 years), and the highest resale returns.

## Biggest Validity Risks

1. **Buyer-finance buckets are not exhaustive.**  
   In `buyer_type_year.csv`, `other_or_unknown` is 36.4% of 2018 transactions and 39.0% of 2024 transactions. The current paper cannot describe "the housing market" as cash versus mortgage until this residual bucket is audited. It may include missing finance flags, non-arm's-length transfers, duplicates, special deeds, seller finance, or other transaction types.

2. **Cash and mortgage flags need a formal mutual-exclusivity audit.**  
   The property scans require `o.cash <> o.mortgage`, but the national audit reports cash and mortgage shares independently. Before any headline share is used, add counts for `(cash, mortgage) = (1,1), (1,0), (0,1), (0,0), missing` by state-year and transaction type.

3. **Corporate cash categories currently overlap with investor and distress categories in some outputs.**  
   `04_buyer_type_decomposition.R` counts `corporate_cash`, `investor_cash`, and `distress_cash` as non-mutually-exclusive cell-level types, while `06_repeat_sale_intermediation.R` uses mutually exclusive priority: distress > investor > corporate > ordinary > mortgage. This is defensible for discovery, but a paper needs one canonical taxonomy plus an overlap appendix.

4. **Ordinary cash is not yet clean enough.**  
   Ordinary cash currently excludes investor, corporate, foreclosure, and REO flags in the type decomposition, but the project has not yet excluded new construction, interfamily transfers, quitclaim/non-warranty deed-like transfers, very stale property records, unusual buyer/seller names, or non-arm's-length transaction codes if available.

5. **Property cells are useful but still coarse.**  
   County-year x property type x bedroom x bathroom x square-footage bin x age bin x owner-occupancy cells reduce obvious composition but leave neighborhood, school district, census tract, condition, renovations, seller motivation, days-on-market, and exact timing uncontrolled. Missing property bins are included as cells, which may mix low-quality records with real market facts.

6. **Repeat-sale returns are not abnormal returns.**  
   The current repeat-sale return facts are not adjusted for county HPI growth, renovations, holding-period selection, transaction costs, distress improvements, or local market timing. Investor/corporate excess returns could be renovation returns rather than acquisition discounts.

7. **Repeat-sale construction may include mechanical duplicates or related transfers.**  
   `06_repeat_sale_intermediation.R` orders transactions by `sale_raw, sale_amount` and keeps consecutive sales with 0.5-6 year holds. It does not yet remove same-day duplicates beyond the positive-hold filter, transfer-cleanliness codes, repeated nominal flips, buyer-seller relatedness, or cases where the next sale is not an arms-length resale.

8. **FRED mortgage-rate overlay is missing in generated annual outputs.**  
   `annual_finance_with_mortgage_rates.csv` has missing `mortgage30us`, and the 2026-06-05 report notes the FRED download timed out. Any figure that claims a mortgage-rate overlay should be regenerated after caching `fred_mortgage30us.csv`.

9. **2024 is partial/lower-volume.**  
   The matched-cell transaction count falls to 2.10 million in 2024 from 3.77 million in 2023 and 4.65 million in 2022. Treat 2024 as partial unless the extract coverage is documented.

10. **No standard errors or formal inference yet.**  
    The current tables are medians, weighted averages, and grouped summaries. A journal draft needs regression equivalents with fixed effects, clustered standard errors, and sensitivity to cell definitions.

## Prioritized Robustness and Extension Roadmap

1. **Canonical classification audit.**  
   Add a state-year and national audit of cash, mortgage, investor, corporate, distress, new construction, resale, and unknown/other categories. Output should include overlap matrices and missingness by state-year.

2. **Define a single mutually exclusive buyer taxonomy.**  
   Use one priority order for all tables. Recommended main taxonomy: mortgage, ordinary_cash, corporate_cash, investor_cash, distress_cash, cash_other_unknown, noncash_nonmortgage_unknown. Then add an appendix overlap table where corporate, investor, and distress are allowed to overlap.

3. **Build a clean ordinary-household cash sample.**  
   Exclude investor, corporate, foreclosure/REO, new construction, interfamily/related transfers if available, and unknown finance conflicts. Re-estimate the ordinary cash gap in the exact same property cells.

4. **Run distress-excluded and institutional-excluded gaps.**  
   Report the headline cash-mortgage gap sequentially: all cash, non-distress cash, non-investor/non-corporate cash, clean ordinary cash. This will show how much of the headline "cash discount" survives composition cleaning.

5. **HPI-adjust repeat-sale returns.**  
   Add FHFA county or ZIP HPI and compute abnormal annualized returns: realized repeat-sale log return minus local HPI growth over the same hold. Then rerun by purchase type, state, purchase year, and holding-period bin.

6. **Add repeat-sale fixed-effect regressions.**  
   Estimate abnormal return models with purchase county x purchase year fixed effects, resale year fixed effects, holding-period bins, and buyer-type indicators. Cluster at county or county-year. Start with all pairs, then clean arms-length pairs.

7. **Split repeat-sale returns by resale buyer finance.**  
   Investor/corporate acquisition followed by resale to mortgage buyer is closer to an intermediation mechanism. Report returns separately for resale-to-mortgage, resale-to-cash, and resale-to-other/unknown.

8. **Move from county-year cells to finer geography where feasible.**  
   For high-coverage states or metros, rerun property-adjusted gaps using county-month and ZIP-year or tract-year cells. The paper needs to show that the core decomposition is not a county-year composition artifact.

9. **Mortgage-friction validation design.**  
   Build county-level outcomes and interact post-2022 with pre-shock mortgage dependence. Outcomes: cash share, ordinary cash share, corporate/investor cash shares, clean ordinary-cash gap, and transaction volume. Candidate pre-shock measures: 2018-2021 mortgage share in CoreLogic, HMDA mortgage origination dependence, or local rate exposure proxies.

10. **External validity and geography audit.**  
    Add coverage maps/tables: transactions by state-year, matched-cell inclusion rates, repeat-sale inclusion rates, and excluded unknown/other shares. The paper should disclose where the national facts are strongest and weakest.

## Table and Figure Readiness Grades

| Output | Current file(s) | Grade | Reason |
|---|---|---:|---|
| National annual finance shares | `national_year_finance_shares.csv`, `annual_finance_with_mortgage_rates.csv` | B- | Good descriptive base, but unknown/other finance bucket and missing mortgage-rate overlay prevent draft use. |
| Monthly finance shares with rate | `cash_mortgage_shares_with_rate.png`, `monthly_finance_with_mortgage_rates.csv` | C+ | Useful exploratory figure; not draft-ready until FRED overlay is cached and unknown categories are shown. |
| State post-2022 cash-share shifts | `state_post_2022_finance_shift.csv`, `state_cash_share_shift_post_2022.png` | B- | Interesting local heterogeneity, but needs coverage filters, volume changes, and interpretation beyond raw shifts. |
| Property-adjusted yearly cash gap | `property_adjusted_gap_by_year.csv`, `property_adjusted_gap_by_year.png` | B | Strong descriptive table; needs standard errors, cleaner samples, and sensitivity to cell definitions. |
| Property-cell gap distribution | `property_cell_cash_mortgage_gaps.csv`, `property_cell_gap_distribution.png` | C+ | Good discovery diagnostic; too many cells and no geography/sample audit for main-text use. |
| State property-adjusted gaps | `property_adjusted_gap_by_state_year.csv`, `state_property_adjusted_gap_2024.png` | C+ | Useful for targeting heterogeneity; 2024 partial coverage and small cash counts make current ranking risky. |
| Buyer-type gap decomposition | `cash_type_property_adjusted_gap_by_year.csv`, `cash_type_property_adjusted_gap_by_year.png` | B+ | Best current main-text candidate; must harmonize overlapping versus mutually exclusive classifications. |
| Repeat-sale return summary | `repeat_sale_returns_by_purchase_type.csv`, `repeat_sale_returns_by_purchase_type.png` | B- | Mechanism-relevant and large-N; not publishable until HPI-adjusted and cleaned for renovations/arms-length concerns. |
| Repeat-sale by purchase year | `repeat_sale_returns_by_purchase_year_type.csv`, `repeat_sale_returns_by_purchase_year_type.png` | C+ | Useful diagnostic; needs confidence intervals and controls for changing hold windows. |
| Repeat-sale state summary | `repeat_sale_returns_by_state_type.csv` | C | Good appendix candidate after HPI adjustment and minimum-count/coverage thresholds. |

## Exact Scripts and Files to Add Next

1. `projects/02_cash_buyer_premium/scripts/R/08_classification_audit.R`  
   Outputs:
   - `classification_overlap_national_year.csv`
   - `classification_overlap_state_year.csv`
   - `finance_flag_crosswalk_state_year.csv`
   - `unknown_finance_share_state_year.csv`
   - `classification_audit.log`

2. `projects/02_cash_buyer_premium/scripts/R/09_clean_sample_definitions.R`  
   Purpose: produce reusable filters/taxonomies for all later scripts.  
   Outputs:
   - `clean_buyer_taxonomy_counts.csv`
   - `clean_sample_state_year_counts.csv`
   - `clean_sample_definitions.md`

3. `projects/02_cash_buyer_premium/scripts/R/10_clean_cash_gap_decomposition.R`  
   Purpose: rerun property-cell gaps sequentially under all-cash, non-distress, non-institutional, and clean ordinary-cash definitions.  
   Outputs:
   - `clean_cash_gap_by_year.csv`
   - `clean_cash_gap_by_state_year.csv`
   - `clean_cash_gap_by_cell_definition.csv`
   - `clean_cash_gap_by_year.png`

4. `projects/02_cash_buyer_premium/scripts/R/11_fetch_fhfa_hpi.R`  
   Purpose: cache county or ZIP HPI for repeat-sale adjustment.  
   Outputs:
   - `data/external/02_cash_buyer_premium/fhfa_county_hpi.csv`
   - `data/external/02_cash_buyer_premium/fhfa_zip_hpi.csv` if feasible
   - `fhfa_hpi_coverage.csv`

5. `projects/02_cash_buyer_premium/scripts/R/12_repeat_sale_hpi_adjusted.R`  
   Purpose: compute HPI-adjusted repeat-sale returns using the existing `repeat_sale_pairs_2018_2024.csv` or a filtered pair table.  
   Outputs:
   - `repeat_sale_hpi_adjusted_pairs.csv` or parquet if too large
   - `repeat_sale_hpi_adjusted_by_purchase_type.csv`
   - `repeat_sale_hpi_adjusted_by_hold_bin.csv`
   - `repeat_sale_hpi_adjusted_by_state_type.csv`
   - `repeat_sale_hpi_adjusted_returns.png`

6. `projects/02_cash_buyer_premium/scripts/R/13_repeat_sale_regressions.R`  
   Purpose: fixed-effect regressions of HPI-adjusted returns by buyer type.  
   Outputs:
   - `repeat_sale_regression_models.rds`
   - `repeat_sale_regression_table.csv`
   - `repeat_sale_regression_table.md`

7. `projects/02_cash_buyer_premium/scripts/R/14_resale_buyer_split.R`  
   Purpose: split repeat-sale intermediation by resale finance type.  
   Outputs:
   - `repeat_sale_returns_by_purchase_and_resale_type.csv`
   - `repeat_sale_returns_purchase_resale_heatmap.png`

8. `projects/02_cash_buyer_premium/scripts/R/15_geography_sensitivity.R`  
   Purpose: rerun cash gaps using county-year, county-month, ZIP-year, and tract-year where feasible.  
   Outputs:
   - `cash_gap_geography_sensitivity.csv`
   - `cash_gap_geography_sensitivity.png`

9. `projects/02_cash_buyer_premium/scripts/R/16_mortgage_friction_validation.R`  
   Purpose: county panel design around the 2022 rate shock interacted with pre-shock mortgage dependence.  
   Outputs:
   - `county_finance_outcomes_2018_2024.csv`
   - `mortgage_friction_validation_models.rds`
   - `mortgage_friction_validation_table.csv`
   - `mortgage_friction_event_study.png`

10. `projects/02_cash_buyer_premium/scripts/R/17_write_empirical_results_report.R`  
    Purpose: replace discovery memos with a consolidated analysis-ready report.  
    Output:
    - `projects/02_cash_buyer_premium/quality_reports/specs/2026-06-XX_empirical_results_for_draft.md`

## Draft-Readiness Gate

Do not move to a publication-style draft until the project has:

- A documented canonical buyer taxonomy with overlap appendix.
- A clean ordinary-cash estimate and a sequential decomposition from all cash to clean ordinary cash.
- HPI-adjusted repeat-sale returns with fixed-effect regression tables.
- A finance-flag residual/unknown audit.
- A 2024 coverage note or restriction that avoids treating partial-year artifacts as economics.
- At least one local mortgage-friction validation table showing whether the 2022 shock changed composition or gaps in predictable places.

Once those are complete, the paper can credibly frame itself around three main facts: cash discounts are heterogeneous, institutional/distress cash explains much of the headline gap, and investor/corporate cash transactions look like intermediation rather than ordinary household financing certainty.
