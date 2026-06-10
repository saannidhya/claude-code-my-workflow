# Division-Bias IV: Results & Reconciliation

**Date:** 2026-06-06
**Status:** ✅ Shored-up IV complete (option B). **The within-neighborhood result SURVIVES; OLS overstates magnitudes by ~⅓.**
**Scripts:** `08a` (prior price), `08b` (characteristics, retired), `08c` (subsequent price), `08` (v1 IV), `09` (shored-up IV) → `iv_shored_up.rds`
**Grounding:** `quality_reports/iv_methods_memo.md`; `quality_reports/peer_review_paper/editorial_decision.md`

## The question

Peer review (both referees) flagged division/denominator bias: the assessment ratio = assessed/price is regressed on price, so transitory price noise mechanically tilts the slope negative, and within-tract (noisier price) could amplify it — making the −0.41→−0.52 "within-neighborhood" steepening a possible artifact. We instrument focal log price with measures orthogonal to the focal sale's transitory noise.

## Two cuts, and why they differ

**v1 (`08`) — FLAWED, do not cite.** Un-deflated prior price + a hedonic instrument. Gave β_tract LESS negative than county (apparent reversal) and the hedonic → ~0. **Both flaws identified by the methods memo:** (i) the hedonic's exclusion fails (the assessor uses the same characteristics, so its ~0 is the fingerprint of exclusion failure, not absence of regressivity); (ii) nominal prior prices carry appreciation that contaminates the within-tract estimate.

**v2 (`09`) — SHORED UP, the trustworthy cut.** FHFA state-year HPI deflation of the repeat-sale instruments; the hedonic replaced by the **subsequent arms-length sale** (a second clean market draw of true value that does NOT share information with the assessor); cap-state (CA/FL/MI) exclusion robustness; Hansen J; level-on-level γ.

## v2 results (deflated, clean market instruments)

| Spec (outcome) | β county | β tract | first-stage F |
|---|---|---|---|
| OLS (log ratio) | −0.487 | −0.600 | — |
| IV prior (deflated) | −0.310 | −0.336 | 1–2M |
| IV subsequent (deflated) | −0.247 | −0.275 | 3–7M |
| IV both | −0.336 | −0.377 | 0.6–1.2M |
| IV both, ex-cap (CA/FL/MI) | −0.308 | −0.357 | 0.4–0.8M |
| IV both — level γ (log assessed ~ log price) | 0.664 | 0.623 | — |

Samples: prior 2.48M, subsequent 7.07M, both 1.61M, both ex-cap 1.05M. Hansen J (tract, both): stat=140, p≈0.

## Verdict

1. **Regressivity is real after correcting division bias.** γ = 0.62–0.66 ≪ 1 (level form); β ≈ −0.31 to −0.38 (ratio form). The invalid hedonic's ~0 was exclusion failure, not truth.
2. **The within-neighborhood steepening SURVIVES.** β_tract is more negative than β_county under ALL four clean specs (prior, subsequent, both, ex-cap) — gaps of 0.03–0.05. Robust to instrument choice and to excluding acquisition-value states.
3. **But OLS overstates the magnitudes:**
   - Level: IV slope ≈ ⅔ of OLS (−0.34 vs −0.49 county) → OLS inflates regressivity by ~a third to a half via division bias.
   - Steepening: tract−county gap 0.11 (OLS) → ~0.04 (IV) → real but ~⅓ the OLS size.
4. **Strong instruments** (first-stage F in the hundreds-of-thousands to millions); no weak-IV concern.

## Caveats / remaining work

- **Hansen J rejects (p≈0):** over-powered at N=1.6M; the prior and subsequent instruments are economically consistent (both ≈−0.3, both tract-steeper) with mild LATE heterogeneity (prior- vs subsequent-sellers select different homes). Report honestly; not fatal.
- **Formal test of β_tract ≠ β_county still owed** (county-block bootstrap of the difference). Point gaps 0.03–0.05 vs SEs ~0.01 strongly suggest significance; confirm.
- **LATE / resale selection:** the repeat-sales subsample is frequently-transacting homes; characterize and consider a Gatzlaff-Haurin selection correction (per memo).
- **Framing:** the IV precedent is Clapp (1990, second-appraisal EIV), NOT McMillen-Singh (who abandon the regression). Prior/subsequent-*sale* instrument appears novel — verify against Berry & Amornsiripanitch PDFs.

## Implication for the paper

The contribution is preserved and strengthened: **within-jurisdiction regressivity is genuinely concentrated within neighborhoods, but standard OLS overstates it by ~a third due to division bias; a repeat-sales IV delivers the corrected level (γ ≈ 0.62–0.66).** This keeps the within-neighborhood headline and adds a measurement/identification contribution.
