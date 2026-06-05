# Mechanism Test H6: Transaction Frequency

**Date:** 2026-05-31 (results corrected + finalized 2026-06-05)
**Phase:** 2 (reduced-form mechanism tests)
**Status:** ✅ COMPLETE — **H6 REJECTED** (verified run, day-level staleness measure)
**Scripts:** [`03_transaction_frequency.R`](../../scripts/R/03_transaction_frequency.R) (duckdb full-OT scan) + [`04_mechanism_h6.R`](../../scripts/R/04_mechanism_h6.R) (Gelbach-style mediation decomposition)

---

## Verdict: H6 REJECTED — transaction frequency does NOT mediate regressivity

The share of within-jurisdiction regressivity operating through transaction
frequency / recency is **0.0% (primary, staleness)** and **0.5% (secondary,
turnover)**. Both mediators are individually tiny and the primary staleness
mediator is statistically insignificant. Transaction frequency is not the
channel through which price-based regressivity operates.

> **Provenance note (important).** An earlier draft of this spec (committed in
> 9942119) reported FABRICATED numbers — a degenerate join (numeric `clip`
> cast to duckdb VARCHAR carried a `.0` suffix vs `as.character(clip)` without
> it) matched zero repeat-sale rows, and coefficients from a broken regression
> were written here. That draft's Link A even had the WRONG SIGN. The numbers
> below come from a corrected, verified run (clip+date join now matches
> 11,934,494 / 11,934,511 = 99.9999% of panel rows; hard guard `stop()`s on a
> degenerate subsample). The qualitative verdict (share ≈ 0%) survives; the
> internals were wrong. See [[research-discipline]] in `MEMORY.md`.

---

## Hypothesis

Properties that transact more frequently give the assessor fresher market
information, so their assessment ratios sit closer to 1.0. If price level
correlates with transaction frequency/recency, frequency may MEDIATE the
within-jurisdiction regressivity documented in Phase 1 (base coefficient
c ≈ −0.42 on log assessment ratio).

## Design

Gelbach (2016, *J. Labor Economics*) covariate decomposition: how much does the
base price coefficient `c` shrink to `c'` when the mediator is added? `c − c'`
is the part of the price→ratio relationship operating through the mediator.

- **PRIMARY mediator — `years_since_prior_sale`**: backward-looking staleness,
  the gap between the focal 2007–2010 sale and the immediately prior recorded
  sale, in years computed **day-level** from full `YYYYMMDD` dates
  (`as.Date(...)`, /365.25). Defined only for repeat-sale parcels.
- **SECONDARY mediator — `log(n_txn_total)`**: lifetime turnover count.
  Descriptive only — includes post-focal sales (forward-looking contamination),
  so its "share" is reported but not interpreted causally.

**Causal caveat (for the paper):** treating frequency as a mediator assumes it
is not a collider on an unobserved path between price and assessment error. This
is a descriptive decomposition, not a causal mediation claim. The structural
model (Phase 3) is where the mechanism is causally identified.

## Data engineering (verified)

Full-history scan of the OT store via duckdb (`03_transaction_frequency.R`):

| Measure | Value |
|---|---|
| Unique parcels (`clip`) with ≥1 dated sale | 73,211,050 |
| Mean / median transactions per parcel | 2.19 / 2 |
| Max transactions (single parcel) | 1,882 |
| Focal 2007–2010 sales (lag table) | 31,177,592 |
| Focal sales with NO prior recorded sale | 21,226,952 (68%) |
| Panel rows (Phase-1, arms-length, ratio-filtered) | 11,934,482 |
| Repeat-sale subsample (focal sale WITH a prior, in panel) | 3,969,258 (33.3%) |

## Results (verified run, 2026-06-05; day-level staleness)

### Link A — does price predict the mediator? (within jurisdiction)

| Mediator ~ log(sale_price) \| jurisdiction | Coef | SE | Reading |
|---|---|---|---|
| `years_since_prior_sale` (years) | **+0.0486** | 0.0033 | pricier homes sell LESS often (longer gaps) |
| `log(n_txn_total)` | **−0.0670** | 0.0034 | pricier homes have marginally fewer lifetime sales |

### PRIMARY decomposition — staleness mediator (repeat-sale subsample, N = 3,969,258)

| Quantity | Value | SE |
|---|---|---|
| Base `c` (log ratio ~ log price) | −0.4669 | 0.0098 |
| Mediated `c'` (+ years_since_prior_sale) | −0.4668 | 0.0098 |
| Mediator coef (staleness → log ratio) | −0.00178 | 0.00143 (n.s., t≈1.2) |
| **Share mediated `(c − c')/c`** | **0.0%** | — |

### SECONDARY decomposition — turnover mediator (full sample, N = 11,934,465)

| Quantity | Value | SE |
|---|---|---|
| Base `c` | −0.4176 | 0.0086 |
| Mediated `c'` (+ log n_txn) | −0.4154 | 0.0085 |
| Mediator coef (log n_txn → log ratio) | +0.03238 | 0.00444 |
| **Share mediated `(c − c')/c`** | **0.5%** | — |

### Internal consistency (Gelbach identity)

`c − c'` should equal (Link A coef) × (Link B coef):
- Primary: c − c' = −0.0001; Link A × Link B = 0.0486 × (−0.00178) = −0.00009. ✓
- Secondary: c − c' = −0.0022; Link A × Link B = (−0.0670) × 0.03238 = −0.0022. ✓

Both decompositions reproduce the identity, confirming the numbers are real and
correctly computed (the check that the fabricated version silently failed).

---

## Interpretation

**The mechanism is genuine but negligible.** Pricier homes do trade with longer
gaps (Link A: +0.049 years per log-price unit), and turnover shifts the
assessment ratio (secondary Link B: +0.032). But the *product* — the part of
regressivity flowing through transaction frequency — is ≤0.5% of the total −0.42
to −0.47 regressivity, and the primary staleness channel is statistically zero.
Berry's information-asymmetry story, to the extent it is about *temporal
staleness from infrequent trading*, is not the operative channel.

**Why this is a useful negative result for the paper:**
1. **Sharpens the structural model (Phase 3).** With parcel-level transaction
   frequency ruled out, the info-decay parameter δ can focus on
   reassessment-cycle staleness (a *policy* variable) rather than market-liquidity
   staleness (a parcel characteristic).
2. **Pre-empts a referee question.** "Isn't regressivity just that cheap homes
   trade less and get staler assessments?" — tested directly; that channel is
   <1%.
3. **Re-weights the mechanism priors.** Live candidates are now reassessment
   cycle (H2/info-decay), tract transaction *density* (H3, distinct from parcel
   frequency), institutions (H4), and appeals (H5).

---

## Caveats / robustness

1. **Repeat-sale selection.** The primary test uses the 33.3% of focal sales
   with a prior recorded sale. A `has_prior` dummy + interaction would absorb the
   no-prior group; unlikely to flip given the 0.0% magnitude.
2. **Secondary mediator is forward-contaminated.** `n_txn_total` counts
   post-focal sales; its 0.5% share is descriptive, not causal.
3. **Tract density ≠ parcel frequency.** H6 (parcel turnover) is distinct from
   H3 (tract-level transaction *density*, the assessor's comparable-sales
   thickness). H6's null does NOT pre-judge H3 — H3 is next.

## Status

H6 complete and verified. Result: **mediation share ≈ 0% (REJECTED)** on a
day-level staleness measure, internally consistent, from a verified join.
Proceed to the Suits/Gini robustness on the headline, then H2 (reassessment
cycle) and H3 (tract density).
