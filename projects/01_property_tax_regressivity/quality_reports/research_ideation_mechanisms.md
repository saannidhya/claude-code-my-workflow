# Research Ideation: Mechanisms of Within-Jurisdiction Property-Tax Regressivity

**Date:** 2026-06-05
**Project:** 01_property_tax_regressivity
**Input:** Next-best testable hypotheses after H6 (transaction-frequency staleness) returned a verified NULL (mediated share ≈ 0%). Must differentiate from Amornsiripanitch (2022) and ideally map to named policy reforms.
**Status:** DRAFT for researcher review — load-bearing claims flagged for CoVe (see Post-Flight block).

## Overview

Phase 1 replicated Berry's core fact: within a taxing jurisdiction, the assessment ratio falls with sale price (elasticity ≈ −0.42 to −0.44), i.e. low-value homes are over-assessed relative to high-value homes. The project's contribution is to **decompose that regressivity into named, policy-relevant mechanisms** and (Phase 3) embed them in a structural model with counterfactuals. H6 (parcel-level transaction frequency / staleness) is now a clean null, which *removes* one candidate and sharpens the remaining menu.

The binding constraint on "what's next" is **differentiation from Amornsiripanitch (2022)**, who already publishes a reduced-form valuation-vs-reappraisal decomposition on national CoreLogic (Philadelphia Fed WP 22-02). ⚠️ The often-cited "~60/40" magnitude is **unconfirmed in primary text** (CoVe could not retrieve the table; a secondary source cites "38% from infrequent reappraisal"). Pull WP 22-02 by hand and quote the exact split before relying on it — do NOT present 60/40 as established. A winning hypothesis must do something his variance decomposition does not: (a) operate at a level he doesn't separate (neighborhood vs parcel), (b) exploit a *shock* for cleaner identification, or (c) isolate an *institution* that maps to a named reform. The five RQs below are ordered descriptive → causal and ranked at the end.

---

## Research Questions

### RQ1: How much of within-jurisdiction price-regressivity is *across-neighborhood* (tract mispricing) vs *within-neighborhood* (parcel valuation error)? (Feasibility: HIGH)

**Type:** Descriptive / decomposition
**Paper type:** descriptive (→ reduced-form once the racial-composition interaction is added)

**Hypothesis:** A large share of Berry's −0.42 operates *across* tracts within a jurisdiction — assessors misprice whole neighborhoods (low-value, disproportionately minority tracts get higher ratios) — rather than within homogeneous neighborhoods. Adding tract fixed effects should attenuate the price-slope materially (predicted: |β| falls by ≥ 1/3); the attenuated portion should load on tract racial/income composition (ACS).

**Identification Strategy:**
- **Method:** FE absorption / variance decomposition. Estimate `log(ratio) ~ log(price)` with (a) jurisdiction FE (Berry baseline), then (b) + tract FE. The change in β is the across-tract share. Then interact the across-tract component with tract % non-white / median income (ACS).
- **Treatment/variation:** parcel sale price within tract vs the tract's position in the jurisdiction.
- **Key assumption:** within-tract parcels face a common neighborhood valuation regime; tract FE absorb neighborhood mispricing.

**Data Requirements:** CoreLogic geocoded to census tract (already geocoded in the baseline Ohio files; national geocoding needs confirmation) · ACS 5-year tract demographics via `tidycensus`.

**Potential Pitfalls:**
1. Tract FE also absorb *real* within-tract price variation → use block-group or a spatial spline as robustness.
2. Mechanical-bias (McMillen-Singh 2023): pair with a Suits/Gini gap computed within vs across tracts.

**Related Work / novelty boundary (CoVe-checked):** Berry (2021) stops at the jurisdiction. **Avenancio-León & Howard (2022) already decompose the *racial* gap between vs within neighborhood (~half between)** and control the price-regressivity away — so the race interaction here *connects to*, not leapfrogs, them. The defensible novel object is the within-tract vs across-tract decomposition of the **price** slope (Berry's object), which they do not decompose. Abbott & Smith (2021, Pittsburgh; tract insensitivity) and Meng Liu (2026, Cook County; price-vs-within-price race decomposition) are adjacent but distinct. Frame the contribution explicitly against these three or a referee will cite them.

---

### RQ2: Does assessment staleness *interacted with the 2007–2010 price shock* drive regressivity, scaled by the jurisdiction's reassessment cycle? (Feasibility: MEDIUM-HIGH)

**Type:** Causal / mechanism
**Paper type:** reduced-form (triple-difference)

**Hypothesis:** Regressivity is amplified where assessments are stale (long statutory reassessment cycle) AND local prices fell hardest, because the low-value segment fell most in % terms during the bust and stale assessed values failed to follow. Predicted: the price-slope steepens with (cycle length × local price decline). This turns the project's main *limitation* — the 2007–2010 bust window — into the identifying variation, and maps directly to the **annual-reassessment** reform.

**Identification Strategy:**
- **Method:** triple-difference: `log(ratio) ~ log(price) × cycle_length × Δprice_local`, with county + sale-year FE.
- **Treatment:** statutory reassessment-cycle length (policy, cross-state/county); local price decline 2007→2010.
- **Control:** short-cycle and/or stable-price jurisdictions.
- **Key assumption:** cycle length is not correlated with unobserved drivers of the price-regressivity slope conditional on FE (defensible — cycles are set by old statute).

**Data Requirements:** Lincoln Institute *Significant Features of the Property Tax* (reassessment-cycle frequency by state) · local price decline from CoreLogic repeat-sales or FHFA/Zillow ZHVI.

**Potential Pitfalls:**
1. Cycle length is coarse (often state-level) → limited within-state variation; consider county-level reassessment practice where available.
2. Bust severity correlates with subprime exposure, itself value-correlated → control for tract credit/LTV proxies.

**Related Work:** Amornsiripanitch (2022) (reappraisal frequency, but no shock); Krupa (2014); Mikesell (1980).

---

### RQ3: In assessment-cap (acquisition-value) states, is regressivity driven by *tenure* rather than valuation error? (Feasibility: HIGH)

**Type:** Causal / institutional
**Paper type:** reduced-form (cap vs non-cap, with tenure decomposition)

**Hypothesis:** In states with assessment caps / acquisition-value regimes (e.g., CA Prop 13, FL Save Our Homes, MI), assessed value tracks purchase price + capped growth, so within-jurisdiction regressivity is mechanically generated by **holding period**, not mass-appraisal error. Predicted: in cap states the price-ratio slope is steeper and is largely explained by years-since-purchase; in non-cap states tenure explains little and valuation error dominates. Maps to the **assessment-cap** policy.

**Identification Strategy:**
- **Method:** decompose β by regime — `log(ratio) ~ log(price) (+ tenure)` separately for cap vs non-cap states; Gelbach decomposition of how much of β tenure absorbs.
- **Treatment:** state cap regime (known institutional taxonomy).
- **Key assumption:** the cap taxonomy is exogenous to the parcel-level slope conditional on FE.

**Data Requirements:** CoreLogic purchase date → tenure (in hand) · state cap-regime classification (Lincoln Institute / Significant Features).

**Potential Pitfalls:**
1. Cap states differ on many margins → use only within-cap-state variation in tenure for the mechanism, cross-regime only for the headline contrast.
2. Tenure correlates with price appreciation → that *is* the mechanism, but separate it from genuine valuation error.

**Related Work:** Hou, Ding, Schwegman & Barca (2023) (AVI); Ihlanfeldt & Rodgers (2022) (homestead).

---

### RQ4: Do property-tax *appeals* function as a wealth technology that pulls down high-value assessments? (Feasibility: LOW-MEDIUM)

**Type:** Causal / mechanism
**Paper type:** reduced-form (institutional IV) or descriptive

**Hypothesis:** High-value/high-resource owners appeal more and win more, so *observed* (post-appeal) ratios are depressed at the top → regressivity. Predicted: where appeals are cheaper/easier (institutional variation), the price-slope is steeper.

**Identification Strategy:** exploit cross-jurisdiction variation in appeal cost (deadlines, burden of proof, filing fees) from IAAO; institutional-feature IV for appeal propensity.

**Data Requirements:** appeals microdata (scarce nationally) OR IAAO appeal-process features · CoreLogic cannot observe appeal outcomes directly — **this is the binding constraint**.

**Potential Pitfalls:** without appeals microdata this is an institutional reduced form, not a direct test; appeal-process features correlate with other assessor quality.

**Related Work:** Doerner & Ihlanfeldt (2014); Cai & Wiley (2025); McMillen (2013).

---

### RQ5: Do assessor *institutions* (elected vs appointed; mass-appraisal/CAMA quality) modulate regressivity? (Feasibility: MEDIUM)

**Type:** Causal / institutional
**Paper type:** reduced-form (cross-sectional, institutional)

**Hypothesis:** Elected assessors facing political pressure, and jurisdictions with weaker CAMA technology, exhibit steeper regressivity. Predicted: β steeper under elected assessors and low-IAAO-standards jurisdictions.

**Identification Strategy:** cross-jurisdiction institutional variation (elected/appointed, IAAO ratio-study compliance) as the moderator of β; FE where panel allows.

**Data Requirements:** IAAO / Census of Governments assessor-institution data · CoreLogic ratios.

**Potential Pitfalls:** institutions are cross-sectional and endogenous to local political economy; hard to rule out omitted local factors.

**Related Work:** Ross (2012); Bowman & Mikesell (1989).

---

## Ranking

Score = Novelty (vs Amornsiripanitch) × Identifiability × Feasibility-with-current-extract.

| RQ | Novelty | Identifiability | Feasibility (2007–2010 in hand) | Priority |
|----|---------|-----------------|-------------------------------|----------|
| **RQ1 — tract decomposition (+race)** | High | High | **High (data in hand)** | **1** |
| RQ2 — staleness × bust shock × cycle | High | Med-High | Med-High (needs Lincoln + price decline) | 2 |
| RQ3 — caps / tenure | High | High | High (needs cap taxonomy) | 3 |
| RQ5 — assessor institutions | Med | Medium | Medium (needs IAAO) | 4 |
| RQ4 — appeals | High | Low-Med | Low (no appeals microdata) | 5 |

## Recommendation — pursue RQ1 next, with RQ2 as the causal follow-up

**RQ1 (the tract decomposition) is the single best next move**, for four reasons:
1. **Zero new data** — CoreLogic + ACS tracts are already in the pipeline, so it can run this week while Lincoln/IAAO data are assembled for RQ2/RQ3.
2. **First-order question neither competitor answers** — Berry stops at the jurisdiction; Amornsiripanitch decomposes *valuation vs reappraisal*, not *neighborhood vs parcel*. "Is regressivity a neighborhood-mispricing problem or a parcel-valuation problem?" reframes the paper.
3. **Connects to the hottest strand — carefully** — the racial-composition interaction links to Avenancio-León & Howard, but (CoVe) they *already* do a between/within-neighborhood decomposition of the **racial gap**, so the novel core must be the **price-slope** spatial decomposition, not the race interaction. Position precisely or a referee cites AL&H.
4. **Disciplines the structural model** — the within/across split tells Phase 3 whether the structural mechanism should live at the parcel or the neighborhood level. It also lets you answer McMillen-Singh by reporting a within-tract Suits gap.

**One–two punch:** RQ1 establishes *where* the regressivity lives (neighborhood vs parcel); **RQ2** then supplies the *causal* mechanism (stale assessments failing to track a price shock, scaled by the reassessment cycle), exploiting the bust window as identification and mapping to the annual-reassessment reform. Together they are clearly differentiated from Amornsiripanitch and give the structural model two disciplined targets.

## Suggested Next Steps

1. **RQ1 now:** confirm national tract geocoding in the CoreLogic prop extract (the baseline Ohio files are geocoded; national coverage needs a check) → build `05_tract_decomposition.R`: jurisdiction-FE vs +tract-FE β, plus the ACS racial-composition interaction and a within-vs-across Suits gap.
2. **Assemble for RQ2/RQ3:** Lincoln Institute *Significant Features* (reassessment cycles + cap taxonomy); a local price-decline series (CoreLogic repeat-sales or FHFA).
3. **Bibliography:** run `/verify-claims` on the lit-review `.bib`, then deepen Avenancio-León & Howard (2022) and Amornsiripanitch (2022) for the positioning section.
4. **H6 stays in the paper** as the clean null that motivates moving from parcel-level to neighborhood-level and policy mechanisms.

---

## Post-Flight Verification (CoVe) — 2026-06-05

Fresh-context `claim-verifier` checked 8 load-bearing claims via WebSearch/WebFetch (it never saw this draft). Outcome: **5 SUPPORTED, 2 PARTIALLY-SUPPORTED, 1 hedged; no outright contradictions.**

| # | Claim | Verdict |
|---|-------|---------|
| 1 | Amornsiripanitch (2022) Philly Fed WP 22-02, CoreLogic, ~60/40 valuation/reappraisal | **PARTIAL** — paper/venue/data ✓; **60/40 magnitude UNCONFIRMED** (verify by hand) |
| 2 | Avenancio-León & Howard, "Assessment Gap," QJE 2022, within-juris minority over-assessment | SUPPORTED (QJE 137(3):1383–1434) |
| 3 | McMillen & Singh (2023, J. Housing Econ.) OLS regressivity measure mechanically biased | SUPPORTED |
| 4 | Berry (2021) elasticity −0.37 on ~26M sales | SUPPORTED — nuance: Berry frames it as elasticity of the **tax rate** (≡ assessment ratio only under constant statutory rate); make this equivalence explicit in the paper |
| 5 | Lincoln "Significant Features" covers reassessment cycle + cap taxonomy | SUPPORTED |
| 6 | NEGATIVE: nobody decomposes the **price**-slope within-tract vs across-tract (+ race) | **PARTIAL** — strict object survives, but AL&H (between/within racial gap), Abbott & Smith (2021), Meng Liu (2026) are close; sharpen novelty to the price-slope object |
| 7 | CoreLogic generally has tract geocoding + sale dates (tenure) | SUPPORTED — hedge: completeness varies by tier/vintage; may need to geocode parcels ourselves, not assume clean tract IDs |
| 8 | Prop 13 (CA), Save Our Homes (FL), Proposal A (MI) are assessment/acquisition-value caps | SUPPORTED |

**Plan-relevant reconciliations:**
- **Do not cite "60/40."** Pull WP 22-02 / SSRN 3729072 and quote the exact decomposition table before positioning against it.
- **RQ1 novelty reframed** to the price-slope spatial decomposition (above), explicitly distinguished from AL&H / Abbott & Smith / Meng Liu. Net effect: RQ1 stays the best *immediate* step on feasibility, but it is a **descriptive foundation**, not the headline contribution — that title shifts to RQ2/RQ3 (uncontested novelty, policy-mapped).
- **RQ1 tract-geocoding dependency is real**, not a formality: confirm national geocoding quality in the extract before building; budget for geocoding parcels to tract if the extract's tract IDs are sparse.
- **New citations to add** (for `/verify-claims` → bib): Abbott & Smith (2021, Pittsburgh property-tax regressivity & race); Meng Liu (2026, Cook County algorithmic assessment).
