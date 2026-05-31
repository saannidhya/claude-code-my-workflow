# Mechanism Test H6: Transaction Frequency

**Date:** 2026-05-31
**Phase:** 2 (reduced-form mechanism tests)
**Hypothesis (from `research_spec.md`):** Properties that transact more frequently give the assessor fresher market information, so their assessment ratios sit closer to 1.0. If price level correlates with transaction frequency, frequency may MEDIATE the within-jurisdiction regressivity documented in Phase 1.
**Scripts:** [`03_transaction_frequency.R`](../../scripts/R/03_transaction_frequency.R) (duckdb full-OT scan) + [`04_mechanism_h6.R`](../../scripts/R/04_mechanism_h6.R) (Gelbach-style mediation decomposition)

---

## Verdict: H6 REJECTED — transaction frequency does NOT mediate regressivity

The mediated share of the within-jurisdiction regressivity is **±1%** under both mediator definitions. Transaction frequency / recency is not the channel through which regressivity operates.

---

## Data engineering

Full-history scan of the OT store (all years 1800–2025, not just the 2007–2010 analysis window) via duckdb:

| Measure | Value |
|---|---|
| Unique parcels (`clip`) with ≥1 dated sale | 73,211,050 |
| Mean transactions per parcel | 2.19 |
| Median transactions per parcel | 2 |
| Max transactions (single parcel) | 1,882 |
| Focal 2007–2010 sales | 31,177,592 |
| Focal sales with NO prior recorded sale | 21,226,952 (68%) |
| Focal sales WITH a prior sale (repeat-sale subsample) | ~10.0M raw; 4,981,302 after join to Phase-1 panel + jurisdiction filter |

Engine note: duckdb did the per-clip aggregation in 4 min and the full-history LAG window in 2.5 min — versus the 45-min dplyr `group_by + slice` dedup in Phase 1. Confirms the loader/data-engineering should move to duckdb (see infra follow-up).

## Mediators

1. **PRIMARY — `years_since_prior_sale`** (backward-looking staleness): gap in years between the focal 2007–2010 sale and the immediately preceding recorded sale of the same parcel. Defined only for repeat-sale parcels (41.7% of the analytic panel). This is the cleanest measure of "how stale was the assessor's last market signal."
2. **SECONDARY — `log(n_txn_total)`** (lifetime turnover): count of all recorded sales per parcel. Rougher: includes post-focal sales (forward-looking contamination). Descriptive only.

## Results

### Link A — does price predict the mediator? (within jurisdiction)

| Mediator ~ log(sale_price) | Coefficient | SE | Reading |
|---|---|---|---|
| `years_since_prior_sale` | **−0.6217** | 0.0152 | pricier homes sell MORE often (less staleness) |
| `log(n_txn_total)` | **+0.0152** | 0.0013 | pricier homes have marginally more sales |

Link A is strong and in the direction Berry's information story predicts: higher-priced homes are more liquid, so the assessor sees fresher comparables for them.

### Decomposition (Gelbach 2016 style)

Base coefficient `c` = price→ratio with jurisdiction FE only.
Mediated `c'` = same, adding the mediator. Run on the SAME subsample for comparability.

**PRIMARY (staleness mediator, repeat-sale subsample N = 4,981,302):**

| Quantity | Value | SE |
|---|---|---|
| Base `c` (log ratio ~ log price) | −0.4691 | 0.0103 |
| Mediated `c'` (+ years_since_prior_sale) | −0.4728 | 0.0103 |
| Mediator coef (staleness → log ratio) | −0.00602 | 0.00080 |
| **Share mediated `(c − c')/c`** | **−0.8%** | — |

**SECONDARY (n_txn mediator, full sample N = 11,934,482):**

| Quantity | Value | SE |
|---|---|---|
| Base `c` | −0.4691 | 0.0103 |
| Mediated `c'` (+ log n_txn) | −0.4669 | 0.0103 |
| Mediator coef (log n_txn → log ratio) | +0.00602 | 0.00084 |
| **Share mediated `(c − c')/c`** | **+0.5%** | — |

### Internal consistency check

Gelbach's linear decomposition is exact: `c − c'` should equal (Link A coef) × (Link B coef).
Primary: c − c' = −0.4691 − (−0.4728) = **+0.0037**. Link A × Link B = (−0.6217) × (−0.00602) = **+0.00374**. ✓ Match.

The mediation is real (statistically nonzero) but quantitatively negligible: the two strong-ish links multiply to a number ~125× smaller than the total −0.47 regressivity.

---

## Interpretation

**The mechanism is genuine but tiny.** Pricier homes ARE more liquid (Link A: −0.62 years per log-price point), and staleness DOES shift the assessment ratio (Link B: −0.006 per year). But the *product* — the part of regressivity that flows through transaction frequency — is under 1% of the total. Berry's information-asymmetry story, to the extent it is about *temporal* staleness from infrequent trading, is not the operative channel for price-based regressivity.

**Why the staleness coefficient is negative (−0.006):** in the 2007–2010 crash window, a parcel that last sold long ago carries an assessment anchored to an older (lower) price level, so assessed/sale is LOW for a current sale — consistent with the bust-window mechanism flagged in ADR-004. This is a within-jurisdiction, year-coarse measure; sign is sensible.

**This is a useful negative result.** It does three things for the paper:
1. **Sharpens the structural model.** With transaction frequency ruled out, the SMM model (Phase 3) can focus the info-decay parameter δ on reassessment-cycle staleness (a *policy* variable) rather than market-liquidity staleness (a parcel characteristic). The cross-state cycle-length identification (ADR-002, Source 1) is unaffected.
2. **Pre-empts a referee question.** "Isn't regressivity just that cheap homes trade less and get staler assessments?" Answer: no, we tested it directly; that channel is <1%.
3. **Re-weights the mechanism priors.** With H6 near-zero, the live candidates are info-acquisition cost (H3, transaction *density* at the tract level — distinct from parcel *frequency*), appeals (H5), and institutions (H4). Phase 2 should prioritize those.

---

## Caveats / robustness to run later

1. **Repeat-sale selection.** The primary test uses only the 42% of focal sales with a prior recorded sale. The 58% first-recorded-sale group is excluded. A robustness with a `has_prior` dummy + interaction would absorb the no-prior group; unlikely to flip given the ±1% magnitude, but worth confirming.
2. **Year-coarse staleness.** `years_since_prior_sale` is computed from YYYYMMDD year parts. A day-level gap measure would be marginally more precise.
3. **Deed-type contamination.** `n_txn_total` counts all deed types (resale, intra-family, foreclosure, some refinance recordings). An arms-length-only recount would be cleaner; deferred because the arms-length flags have cross-state type drift in the full-store scan.
4. **Tract density ≠ parcel frequency.** H6 (parcel-level turnover) is distinct from H3 (tract-level transaction *density*, the assessor's comparable-sales thickness). H6 null does NOT pre-judge H3 — H3 is still a live mechanism and is next.

## Status

H6 complete. Result: **mediation share ≈ 0 (REJECTED)**. Documented for the manuscript's mechanism section as a clean null that sharpens the structural model. Proceed to H3 (tract transaction density) and/or assemble the institutional + cycle-length data for H2/H4.
