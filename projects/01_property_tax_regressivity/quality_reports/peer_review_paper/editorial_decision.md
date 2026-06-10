# Editorial Decision — "Property Tax Assessment Regressivity"

**Date:** 2026-06-06
**Target journal:** Journal of Public Economics (JPubE) — field calibration (no shipped profile; calibrated from brief)
**Pipeline:** `/review-paper --peer` — 2 independent referees (substance + methods), blind to each other, + cross-artifact reproducibility pre-flight.

## Decision: MAJOR REVISION / REJECT-AND-RESUBMIT

Both referees independently reached the same verdict: the writing, framing, and engineering are strong, but **the headline result is currently indistinguishable from a mechanical artifact (division/denominator bias).** It is **addressable** — the data and code infrastructure to fix it already exist — but as written the central claim is unidentified, so the manuscript cannot be accepted in its current form.

- **Substance referee:** Major Revision (identification 2/5, overall 2.5/5).
- **Methods referee:** Reject, resubmission encouraged (38/100; division-bias FAIL is the binding constraint).
- **Cross-artifact reproducibility (Phase 0):** PASS — every headline number reproduces from the saved outputs exactly (Berry −0.4176, pooled −0.1754, β_county −0.4104, β_tract −0.5160, 53,903 tracts, H6 0.0/0.5%, trim −0.5164, rank −0.48/−0.53). The numbers are real; the *interpretation* is the problem.

## The binding concern (both referees, independently): division bias

The outcome is the assessment ratio = assessed / price, regressed on price. Writing log price = log true-value + transitory noise `u`:
- log(ratio) = log(assessed) − log(price), and log(price) is on the RHS, so OLS is biased toward −1 by −σ²ᵤ / Var(log price) — the McMillen-Singh (2023) mechanic. Even a perfectly proportional assessor yields β < 0.
- **Within a tract, price variation across near-identical homes is disproportionately noise (`u`), not true value.** Tract FE absorb the between-tract true-value signal, raising σ²ᵤ/Var(log price) within group → β driven *more* negative. **The −0.41 → −0.52 steepening is exactly what pure measurement error predicts**, with no "neighborhood anchoring" required. The causal story and the artifact are observationally equivalent on the current evidence.

**My robustness check does not rebut this (both referees).** The abstract/§5 claim the Spearman rank statistic is "immune by construction." It is immune to McMillen's *regression-slope* bias — a *different* bias. The ranked ratio still contains price, so the rank correlation inherits the same negative mechanic; it going more negative within-tract (−0.48 → −0.53) is again what more within-tract noise predicts. **This claim is false and must be removed.**

## Unified concern roster

| # | Concern | Severity | Status |
|---|---|---|---|
| C1 | Division bias confounds the headline one-for-one; within-tract steepening is the artifact's signature | FATAL as written | ADDRESSABLE |
| C1b | "Immune by construction" rank-statistic defense is invalid | Major | Fix now (delete/reword) |
| C2 | Mechanism ("anchoring") asserted, not tested — observationally equiv. to ≥3 DGPs | Major | Needs a shrinkage test |
| C3 | No bias-breaking estimator attempted, though the fix is feasible | Major | **The decisive fix** |
| C4 | β_tract − β_county difference & "20%" reported with NO standard error / no test | Major | County-block bootstrap |
| C5 | Assessment vintage NOT matched to sale (`01_clean.R:99-104` keeps latest tax_year, applied to all sales; "largest value" tie-break non-neutral); contradicts "contemporaneous" text; may build in the H6 null | Major | Year-aware re-match |
| m1 | Sample not actually residential-restricted (`01_clean.R:156` TODO) | Minor | Apply Berry land-use filter |
| m2 | Ratio trim [0.01,5.0] is asymmetric & price-dependent | Minor | Sensitivity |
| m3 | "Twenty percent" is really ~26%; reconcile −0.41/−0.42/−0.467 across tables | Minor | Fix arithmetic |
| m4 | n_txn mediator forward-contaminated; disclose in table note | Minor | Note |
| m5 | "Gelbach decomposition" is a single-covariate delta, not the full routine | Minor | Rename |
| m6 | Empty appendix; effective-tax-rate≡ratio equivalence caveat (split-rate/TIF) | Minor | Populate / footnote |

## What survives (do not discard)

- **The Berry replication is exemplary** (both referees) — ex-ante tolerance, independent national sample, reproducible.
- **The H6 transaction-frequency null is clean and citable** *independent of the contested headline* — but C5 (vintage match) could partly build it in, so re-verify after the year-aware match.
- **The within/between-neighborhood vs. Avenancio-León & Howard framing** is a genuine insight — *if* the within-neighborhood result survives identification.

## The fix (C3) — ranked, both referees agree

1. **Level-on-level (cheapest, do first):** regress log(assessed) on log(price), county FE then tract FE, test the coefficient γ against 1. NOTE: algebraically γ = 1 + β_ratio (same sample/FE), so this *reframes* but does not by itself break the errors-in-variables attenuation — it only removes the literal denominator. Necessary but not sufficient.
2. **Repeat-sales IV (the real fix):** instrument the focal log(price) with the parcel's prior (or subsequent) sale price, deflated by a local index. The transitory components at two distinct sale dates are plausibly independent, so the prior sale identifies true value and purges `u` from the RHS. **The repeat-sales linkage already exists** (`03_transaction_frequency.R` computes prior-sale dates; needs prior-sale *prices* added). If β_tract still < β_county under IV → the within-neighborhood result is real. If it collapses → it was the artifact.
3. **Hedonic-residual:** replace log(price) with fitted log-value from a characteristics-only hedonic.

## Refinement roadmap (priority order)

1. **Decisive analysis — repeat-sales IV** (C1, C3): the single addition that determines whether the contribution survives. Extend `03` to carry prior/next sale prices; new `08_iv_division_bias.R`.
2. **Vintage-matched assessments** (C5): year-aware OT→Prop match in `01_clean.R`; re-run everything; re-verify the H6 null.
3. **Inference on the difference** (C4): county-block bootstrap of β_tract − β_county + CI on the share.
4. **Mechanism test** (C2): within-tract shrinkage test (assessment error increasing in distance from tract-mean value).
5. **Honesty fixes (immediate, mandatory regardless of analysis):** delete the "immune by construction" claim; temper the headline to acknowledge the division-bias threat until resolved; fix 26%/"twenty percent"; reconcile coefficients; apply residential filter; populate appendix; rename "Gelbach"; disclose n_txn contamination; effective-tax-rate footnote.
6. **External validity** (M5): year/dispersion splits now; non-crisis vintage when a refreshed extract is available.

## Bottom line

This is a well-executed, well-written paper with a real question and a fatal-but-fixable identification gap. The path to JPubE runs through the **repeat-sales IV**: it is the test that decides whether "regressivity is within-neighborhood" is a finding or an artifact. Everything else is secondary to that.
