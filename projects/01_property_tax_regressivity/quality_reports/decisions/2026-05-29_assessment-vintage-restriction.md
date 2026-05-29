# ADR-004: Restrict initial paper sample to 2007-2010 sales (assessment vintage)

**Status:** ACCEPTED
**Date:** 2026-05-29
**Context:** Phase 1 (Berry replication) data preparation. Discovered during prop-schema inspection in `01_clean.R` design.

## Problem

Berry's replication regression — log(effective_tax_rate) on log(sale_price) with jurisdiction fixed effects — requires *assessment-at-time-of-sale*. We discovered that UC's CoreLogic prop extract is overwhelmingly tax_year 2008-2009 vintage (38.9M rows tax_year=2008, 19.8M rows 2009, ~7M rows 2007, ~1M rows 2006, ~317K rows 2010, scattered rows in other years). The OT (transaction) extract covers 1900–2024, but the prop snapshot is single-vintage circa 2008-2009.

For sales after 2010, the recorded assessment is stale by 4–15+ years relative to the sale date — which means assessment ratios for those sales conflate true regressivity with intervening price appreciation/depreciation. This is a fundamental data constraint, not a code or methodology issue.

## Options considered

### Option A: Use full 2007-2024 OT range; accept stale assessments

Include all sales 2007-2024. For sales after 2010, the recorded assessment is the 2008-2009 vintage. Document and accept the bias.

**Pro:** Maximum sample size (~26M sales matching Berry's). Better statistical power.
**Con:** The within-jurisdiction regressivity estimate is contaminated. For a 2018 sale at $300K with an assessment of $200K (from 2008), the apparent over-assessment is mechanically driven by the 2008 vintage, not by the assessor's contemporaneous judgment. Berry's estimate (-0.37) cannot be apples-to-apples compared. Reviewer will reject this immediately.

### Option B: Restrict to 2007-2010 sales (assessment ≈ contemporary)

Limit Phase 1 replication sample to sales 2007-2010. Assessment vintage is within ~1-2 years of sale. Smaller sample (~10-12M sales projected) but methodologically defensible.

**Pro:** Clean replication. Direct comparability to Berry. No contamination from price drift between assessment and sale. Sample is still very large (~half of Berry's effective sample). Matches Berry's 2007-2017 window at the early end.
**Con:** Cannot extend to 2011-2024 with current data. The structural model identification from cycle-length variation (ADR-002, Source 1) loses the bulk of the time-series. National coverage maintained but temporal coverage is half what Berry had.

### Option C: Obtain a refreshed prop extract from CoreLogic

License a newer prop extract that has 2018-2024 vintage assessments. Then extend the replication to the full Berry window and beyond.

**Pro:** Methodologically ideal. Full sample size. Future-proof.
**Con:** Licensing cost (unknown, possibly substantial). Lead time (weeks to months for academic licensing). Doesn't help Phase 1 timeline at all.

### Option D: Build a synthetic "assessment-at-sale" via interpolation

Use the 2008-2009 assessment plus county-level price appreciation indices (Zillow ZHVI, FHFA HPI) to roll the assessment forward to the sale date. Use the synthetic assessment in the regression.

**Pro:** Allows extending to 2011-2024 without re-licensing.
**Con:** The synthetic assessment is a *mechanical* function of the original assessment and the price index — it cannot capture the actual assessor's regressivity. Effectively introduces a known-direction bias toward zero (under the null of no regressivity, synthetic ratios are constant; under regressivity, they understate it). Reviewer-blocking.

## Decision

**Chose:** Option B (restrict to 2007-2010 sales for Phase 1)

**Rationale:** Methodological cleanliness wins. A 12M-sale, 4-year national sample is more than enough to recover the -0.37 estimate cleanly, and the spec is honest about the data limitation. We pursue Option C in parallel (write a polite request to UC's CoreLogic liaison for a refreshed prop extract; estimated 2-month lead time). If the refreshed extract arrives during Phase 2/3, we extend; if not, the paper is publishable as a 2007-2010 national study with the structural model's identification largely intact (cycle-length variation is cross-sectional, not time-series).

Option A is reviewer-blocking and tempting only because it preserves apparent sample size. Option D introduces a synthetic-construction bias that any structural-model referee would catch immediately.

## Consequences

### Immediate

- `01_clean.R` restricts OT load to `years = 2007:2010` (instead of `2007:2024`)
- Sample size projection: ~10-12M sales (vs. Berry's 26M)
- Spec timeline still feasible: replication target unchanged (`β ≈ -0.37`)
- Add this caveat to the spec's "Data Requirements" table and "Open Questions"

### For Phase 2 (mechanism tests)

- Cross-state cycle-length variation: still identifiable cross-sectionally on the 2007-2010 panel
- Within-jurisdiction tract-density variation: still identifiable on the same panel
- Cross-jurisdiction institutional variation: still identifiable on the same panel
- Cook County 2018 event-study (robustness only): NOT identifiable with current data — defer to v2 paper or post-extract-refresh

### For Phase 3 (structural estimation)

- All three identifying-variation sources remain valid on the restricted sample
- The SMM moment for "reassessment-cycle event-study" (jumps at reassess) — partially limited; works for cycles in 2007-2010, not 2011+
- Counterfactual revenue gap computed on 2007-2010 base; project to national totals via tax-revenue scaling factors

### Action items

- [ ] Add to `research_spec.md`: explicit data limitation paragraph; updated sample-size estimate; updated timeline note
- [ ] Saani to contact UC's CoreLogic academic liaison about prop-extract refresh; record outcome here
- [ ] If refresh available: amend this ADR to SUPERSEDED and write a new ADR-005 extending the sample window

## Rejected alternatives — why not

- **A (use full 2007-2024 with stale assessments):** Methodologically contaminated; reviewer-blocking.
- **C (license refresh):** Pursue in parallel but doesn't block Phase 1; cannot wait.
- **D (synthetic assessment via price index):** Introduces a known-direction bias that defeats the purpose of replicating Berry's pure-assessment-quality estimate.
