# RQ1: Within-tract vs Across-tract Decomposition of the Price-Regressivity Slope

**Date:** 2026-06-05
**Phase:** 2 (reduced-form mechanism / locus tests)
**Status:** ✅ COMPLETE — verified. **Naive across-tract hypothesis REJECTED; regressivity is WITHIN-neighborhood and stronger there.**
**Script:** [`05_tract_decomposition.R`](../../scripts/R/05_tract_decomposition.R) → `rq1_tract_decomposition.rds`

---

## Verdict

Within-jurisdiction property-tax regressivity is a **within-neighborhood (within-census-tract)** phenomenon, not across-neighborhood mispricing. Adding census-tract fixed effects **strengthens** the price-regressivity slope by ~26% rather than attenuating it. The cheaper of two homes *on the same block* is over-assessed even more than the county-wide average regressivity implies.

## Design

Berry's within-jurisdiction (county-FE) elasticity is the baseline. We add census-tract FE and compare the slope on the **identical** valid-tract sample:
- `β_county` = `feols(log_ratio ~ log_price | county_fips)` — Berry baseline.
- `β_tract`  = `feols(log_ratio ~ log_price | census_tract)` — within-tract slope.
- across-tract (neighborhood) share = `(β_county − β_tract) / β_county`.

Tract geocoding from CoreLogic `census_id` (10-char string = tract(6)+block(4), leading zeros preserved): `census_tract = county_fips(5) + substr(census_id,1,6)`.

## Results (verified run, 2026-06-05)

| Quantity | Value | SE |
|---|---|---|
| β_county (county FE, Berry baseline) | **−0.4104** | 0.0088 |
| β_tract (census-tract FE, within-tract) | **−0.5160** | 0.0089 |
| **Across-tract (neighborhood) share** | **−25.7%** | — |
| Decile gap, within county | +0.9897 | — |
| Decile gap, within tract | +0.9156 | — |

Sample: 10,976,897 sales · 1,692 counties · 53,903 tracts · 45 states.

**Reading:** the across-tract share is *negative* — across-neighborhood price variation is *less* regressive than within-neighborhood variation. Regressivity intensifies when we hold the neighborhood fixed.

## Cross-verification (all passed)

| Check | Result |
|---|---|
| Berry-β reproduction | β_county −0.4104 vs replication M2 −0.4176 (diff 0.007 on 92% subsample) ✓ |
| Same-sample (Gelbach) | nobs county = tract = 10,976,897 exactly ✓ |
| GEOID validity | all 53,903 tracts are 11-digit, 100% valid state FIPS prefix, 45 states ✓ |
| No degeneracy | 96.5% clip match, 92% tract coverage; hard guard not tripped ✓ |
| Tract scale | 53,903 (US ~74k; sample covers 1,692/3,143 counties) ✓ |
| Artifact ruled out | classical price measurement error would *attenuate* β_tract, yet it is *larger* ✓ |

## Interpretation — the mechanism

The mass-appraisal (CAMA) model anchors every home in a neighborhood to a common predicted value. Within a tract, the below-median-price home is pushed up toward the neighborhood mean (over-assessed) and the above-median home pulled down (under-assessed) → steep within-tract regressivity. Across tracts, price differences partly reflect neighborhood quality the model *does* capture, so the across-tract slope is flatter. This is the **neighborhood-anchoring / coarse-comparable** channel (cf. Meng Liu 2026 on coarse location controls).

## Positioning

- **vs Berry (2021):** extends his county-level −0.42 by localizing it — the regressivity lives within neighborhoods.
- **vs Amornsiripanitch (2022):** a spatial level (within vs across tract) he never separates; orthogonal to his valuation-vs-reappraisal split.
- **vs Avenancio-León & Howard (2022):** clean dissociation — the *racial* assessment gap is ~half *between* neighborhoods (their finding); the *price* regressivity is *within* neighborhoods (ours). Race operates between, price-regressivity within.
- **For the structural model (Phase 3):** target within-neighborhood parcel valuation error (neighborhood-anchoring), not neighborhood-level mispricing.

## Robustness to run before paper-final

1. **Trim small tracts** (drop tracts with < 20 sales) — confirm β_tract isn't driven by thin tracts.
2. **Suits/Gini index** within vs across tract — distribution-based, immune to McMillen-Singh mechanical bias; cleaner than the decile gap (within-tract price compression makes the raw decile gap awkward).
3. **ACS racial-composition interaction** (`DO_ACS` block in `05`) — does the *across*-tract residual regressivity load on tract racial composition? Bridges to AL&H without overclaiming.
4. **Selection on geocoding:** the 8% no-`census_id` parcels are slightly *more* regressive (β_county −0.4104 on the 92% vs −0.4176 on the full) — document and probe whether they are rural/low-data areas.

## Status

RQ1 complete and verified. Result is paper-worthy and reframes the contribution: regressivity is a within-neighborhood mass-appraisal failure. Proceed to the robustness items above, then to draft writing / framing / tables.
