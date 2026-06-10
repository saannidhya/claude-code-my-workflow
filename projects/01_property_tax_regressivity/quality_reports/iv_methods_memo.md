# Methods Memo — Repeat-Sales IV for Assessment-Regressivity Division Bias

**Project:** `01_property_tax_regressivity` · **Researcher:** Saani Rawat (Marquette)
**Date:** 2026-06-06 · **Status:** DRAFT for researcher review
**Purpose:** Ground the instrumental-variables strategy that instruments the focal
log sale price (RHS of the ratio regression, and denominator of the LHS
assessment ratio) with the same parcel's PRIOR and SUBSEQUENT arms-length sale
prices, deflated by a house-price index, to recover "true value" free of the
focal sale's transitory noise.

> **Grounding note.** Every claim below was researched via WebSearch/WebFetch
> (June 2026), preferring journal / NBER / Fed working-paper sources. Where a
> primary PDF was paywalled (Springer/ScienceDirect 403) or returned as
> un-parseable binary (Berry's Yale PDF, Amornsiripanitch's Philly Fed PDF,
> McMillen & Singh's Syracuse PDF), the relevant fact was triangulated from
> secondary sources (journal abstracts, RePEc, IAAO task-force review, review
> articles) and is **explicitly flagged [UNVERIFIED-PRIMARY]**. Do not move a
> flagged claim into the manuscript until the primary text is checked. Run
> `/verify-claims` on the numeric and attribution claims before manuscript use.

---

## TL;DR — the six answers

1. **McMillen & Singh (2023) do NOT propose IV.** Their remedy for the
   regression-based regressivity bias is to abandon the regression and use
   **distribution-based measures** (Gini-coefficient comparison, a Suits index,
   and a kernel-density / distributional test of log assessed vs. log price).
   The IV remedy in this literature is **Clapp (1990)** — a different,
   older paper — who instruments a noisy value proxy with a **second appraisal**.
2. **Yes — repeat-sales prices as an instrument for true value is a recognized
   approach**, but the canonical precedent uses a *second appraisal* (Clapp 1990),
   not a *prior/subsequent sale*. Using the other-period sale as the EIV
   instrument is a defensible extension grounded in the classic errors-in-variables
   logic (two noisy measurements of the same latent value, with independent
   transitory errors), but I found **no published assessment-regressivity paper
   that uses the prior/subsequent sale specifically as the instrument**. Treat it
   as a novel-but-well-motivated combination, not an off-the-shelf method.
3. **Deflate with the FHFA annual index at the finest geography that is still
   statistically reliable** — tract or ZIP where FHFA's experimental local indices
   exist, else CBSA, else county. FHFA publishes annual repeat-sales indices down
   to tract/ZIP/county; Case-Shiller is metro-only (20 MSAs) and is therefore too
   coarse for a national parcel panel.
4. **The renovation/quality-change threat is real and the literature's upward-bias
   prior.** Standard handling: (a) drop or down-weight short *and* very long
   holding periods, (b) flag building permits / large assessed-improvement jumps
   and drop those parcels, (c) bound the bias by re-estimating on a "no-permit"
   subsample. Case-Shiller's own interval weighting and renovation-deletion rules
   are the precedent.
5. **The hedonic-predicted-value instrument is INVALID here on exactly the
   exclusion ground you suspect.** Because the assessor uses the same recorded
   characteristics to set the assessment, the hedonic prediction enters the
   assessment (the numerator of your ratio) directly — it is correlated with the
   structural error, so it fails exclusion. The ~0 you got is the signature of an
   invalid instrument, not of "no division bias." Repeat-sales prices do not share
   this defect because the transitory error of a *different* transaction is
   plausibly orthogonal to the focal-sale assessment error.
6. **JPubE pre-emption:** (i) The repeat-sales subsample is a self-selected set of
   homes that resell — your estimate is a **LATE for frequently transacting
   homes**; address with selection diagnostics (Gatzlaff & Haurin) and reweighting.
   (ii) **Weak instruments are a non-issue** at N in the millions with one strong
   first stage — but report the first-stage F anyway. (iii) Cluster at the
   jurisdiction (or jurisdiction-year) level. (iv) **Report the level-on-level
   spec** (log assessed on log price, test slope = 1) alongside the ratio spec —
   it is the cleaner, less-mechanically-biased object and is the field's preferred
   regression form.

---

## 1. What remedy does McMillen & Singh (2023) actually propose?

**Citation.** McMillen, Daniel, and Ruchi Singh (2023). "Measures of vertical
inequality in assessments." *Journal of Housing Economics* 61: 101950.
DOI 10.1016/j.jhe.2023.101950. (Lincoln Institute working-paper version exists.)

**The bias they diagnose.** The standard regression-based regressivity coefficient
is mechanically biased toward *finding* regressivity even when none is present.
Their stated source of the bias is a **functional-form mismatch combined with
noise in assessed value**: if assessments are produced by one model (e.g.
log-linear) but regressivity is evaluated with another (e.g. linear), or vice
versa, the measured vertical-inequity statistic is biased. (Confirmed from the
ScienceDirect/Lincoln abstract and the IAAO 2023 task-force review;
**[UNVERIFIED-PRIMARY]** for the exact phrasing — the ScienceDirect full text
returned 403.)

> **Important nuance for your framing.** McMillen & Singh's named bias is a
> *functional-form / model-mismatch* bias in the assessment-generating process.
> Your "division bias" framing (sale price in both the LHS denominator and the
> RHS regressor, inducing a spurious negative slope via common transitory noise)
> is a *related but distinct* mechanism — it is the classic
> **ratio-on-denominator / errors-in-variables** problem. Both push the slope
> toward "regressive." Do not attribute the pure division-bias / EIV story to
> McMillen & Singh as if it were their headline claim; cite them for the broader
> point that *the regression coefficient is an unreliable regressivity statistic*,
> and cite the EIV literature (below) for the division-bias mechanism your IV
> actually fixes.

**Their proposed remedy is NOT instrumental variables.** They propose three
**distribution-based** alternatives that sidestep the regression entirely:

1. **Gini-coefficient comparison** — compare the Gini of assessed values to the
   Gini of sale prices; if assessments are less skewed toward low-value
   properties than prices are, that *is* vertical inequity, measured without a
   regression.
2. **Suits index** — a single progressivity/regressivity index from the
   Lorenz-curve machinery.
3. **A distributional / kernel-density test** of whether log assessed values
   differ statistically from log sale prices across the distribution.

This is consistent with their earlier work (McMillen & Singh 2020, *JREFE*; and a
2018/2021 Monte-Carlo paper) concluding the **PRD is preferable to regression-based
methods because it carries lower bias**. (Secondary-source confirmed via the
Amornsiripanitch citation trail and IAAO review; **[UNVERIFIED-PRIMARY]** on the
"PRD preferable" exact statement.)

**The IV remedy in this literature is Clapp (1990), a separate paper** — see §2.

**Implication for the memo's IV strategy.** You are not "implementing McMillen &
Singh's fix." You are choosing an IV/EIV correction (Clapp-style) *over* their
distribution-based fix, because IV lets you keep an interpretable elasticity (and
a structural mapping to true value) that the Gini/Suits statistics do not give
you. **Recommendation: report BOTH** — the IV-corrected elasticity *and* at least
one McMillen-Singh distribution statistic (Gini or Suits gap) — so a referee
cannot say you ignored the field's preferred robustness object. (This already
appears as a flagged "robustness obligation" in
`quality_reports/lit_review_regressivity_DRAFT.md`, Positioning section.)

---

## 2. Is prior/subsequent repeat-sale price as an instrument for "true value" recognized?

**Short answer: the *idea* (instrument a noisy value proxy with a second
measurement) is canonical and published; the *specific instrument* (the parcel's
other-period sale) is a defensible extension I could not find already published in
the assessment-regressivity literature.**

### The canonical precedent: Clapp (1990)

**Citation.** Clapp, John M. (1990). "A New Test for Equitable Real Estate Tax
Assessment." *Journal of Real Estate Finance and Economics* 3(3): 233–249.

What Clapp does (secondary-source confirmed; the primary PDF was not opened —
**[UNVERIFIED-PRIMARY]** on exact estimator details):

- Recognizes that true market value `V` is unobservable and that the observed price
  `P` is an **error-laden proxy** for `V`, so regressing the ratio on `P` (or on
  log `P`) inherits **measurement-error / attenuation bias** that manifests as
  spurious regressivity.
- **Switches the dependent and explanatory variables** (regresses log assessed
  value on log value rather than ratio on price) AND **uses an instrumental
  variable in place of the noisy `lnA`/`lnP`** to purge the measurement error.
- In his application he instruments using a **second appraisal** of the same
  property (52 Connecticut towns), and shows it removes a substantial part of the
  bias.

This is the direct ancestor of your strategy. The logic is identical; only the
instrument differs (second appraisal → other-period sale).

### Your variant: the other-period sale as the EIV instrument

The errors-in-variables justification is textbook: if `P_focal = V·(1+u_focal)`
and `P_other = V·(1+u_other)` with the **transitory errors `u_focal ⟂ u_other`**,
then `P_other` (deflated to the focal date) is a valid instrument for `V` — it is
correlated with the latent value (relevance) and, conditional on `V`, uncorrelated
with the focal sale's transitory noise that drives the division bias (exclusion).
This is exactly the two-noisy-measurements EIV setup (e.g., the classic
Wald/Durbin grouping and the broader EIV-IV literature).

**What I could and could not verify:**
- **Verified:** repeat-sales transactions are routinely used to net out
  time-invariant unobserved quality (the entire repeat-sales price-index
  literature — Bailey-Muth-Nourse; Case-Shiller — rests on differencing two sales
  of the same unit).
- **Verified:** repeat sales + IV is an established *combination* in applied real
  estate / environmental hedonics (e.g., a repeat-sales-plus-IV stream-restoration
  valuation, *Env. & Resource Econ.* 2021, instruments for endogenous site
  selection).
- **NOT found / [UNVERIFIED]:** a published *assessment-regressivity* paper that
  uses the **prior or subsequent arms-length sale price as the instrument for true
  value to correct division bias**. Berry (2021) and Amornsiripanitch (2022) — the
  two closest national papers — I could not confirm do this (their PDFs were
  paywalled/binary). My working assumption from the secondary literature is that
  **neither uses repeat-sales IV** (Amornsiripanitch's decomposition is reduced-form
  and partial-R²-flavored; Berry's mechanism claim is informal). **Flag:** confirm
  by reading both PDFs locally before claiming novelty in the manuscript.

**Recommendation.** Frame the contribution honestly as: "We adapt the
Clapp (1990) errors-in-variables logic — instrumenting an unobservable true value
with an independent noisy measurement — replacing his second *appraisal* with the
parcel's other-period *transaction*, which is available at national scale in
CoreLogic where repeat appraisals are not." That is a clean, citable lineage.

---

## 3. Conventions for deflating repeat-sale prices

**Recommendation: FHFA annual repeat-sales HPI, at the finest reliable geography
(tract → ZIP → county → CBSA), purchase-only where available, all-transactions for
the small-geography annual series.**

| Index | Geography available | Frequency | Fit for this project |
|---|---|---|---|
| **FHFA HPI** | National, division, **state, CBSA (metro+micro), county, ZIP, census tract** | Annual (small geos), quarterly (large geos) | **Best.** Only index with sub-metro coverage nationally; built from Enterprise repeat sales. Free, transparent, FRED-accessible. |
| **Case-Shiller (S&P CoreLogic)** | National + **20 MSAs only** | Monthly | Too coarse and too few metros for a national parcel panel; useful only as a robustness check in covered metros. |
| Local/CBSA composite | varies | varies | Use the FHFA CBSA series for this rather than a bespoke index. |

**Verified facts (FHFA):**
- FHFA uses a **weighted repeat-sales** method (a modified Case-Shiller geometric
  weighted procedure) and publishes indices down to **county, ZIP, and census-tract**
  levels on an **annual** basis (the small-geography series use the All-Transactions
  data, which includes refinance appraisals; the Purchase-Only series is
  sales-only but coarser).
- Case-Shiller covers the **national index plus 20 metro areas only**, monthly, and
  **deletes/weights down significantly renovated homes** and uses interval weighting
  that down-weights long gaps.

**Geography choice — the trade-off.**
- **Finer geography = better deflation** (you remove local appreciation differences
  that would otherwise contaminate the "true value" recovered from the other-period
  sale).
- **Finer geography = noisier index** (tract-level FHFA series are thin and can be
  suppressed). Use a **fallback ladder**: tract index if it exists and is
  non-suppressed → else ZIP → else county → else CBSA → else state. Record which
  level was used per parcel; report robustness to coarsening the ladder.
- **Purchase-only vs all-transactions:** the all-transactions series (needed for
  small geographies) embeds appraisal-based refis, which is mild circularity for an
  *assessment* paper. Prefer **purchase-only at the CBSA level** as the robustness
  index; use all-transactions only where you need tract/ZIP resolution. Disclose this.

**Mechanical note.** Deflate each non-focal sale to the focal sale's date:
`P_other_deflated = P_other × HPI(focal_date, geo) / HPI(other_date, geo)`. Then
the instrument is (log) `P_other_deflated`. Using *both* a prior and a subsequent
sale gives you up to two instruments → an **over-identified** model, which lets you
run a **Sargan/Hansen overid test** — a cheap, powerful specification check that a
referee will want (and that partially tests the renovation threat in §4).

---

## 4. The renovation / quality-change threat

This is the central validity threat to a repeat-sales instrument, and it is the
direction the index literature believes the bias runs.

**Verified facts:**
- The OECD/IMF RPPI consensus is that repeat-sales bias is **likely upward**:
  renovations/improvements typically outweigh depreciation, so the second sale
  reflects a *better house*, not just appreciation of the same house.
- **Case & Shiller's own remedy** is to **delete repeat sales of significantly
  renovated homes**, and to use **interval weighting** that down-weights pairs with
  long gaps (longer gaps → more unobserved quality change → higher variance).

**Why it threatens *your* instrument specifically.** If the other-period sale
reflects post-renovation value, then `P_other` is not a noisy measurement of the
*same* `V` as the focal sale — it measures a different (improved) asset. The
exclusion restriction (`u_other ⟂ focal assessment error | V`) and even relevance
to the *focal-date* `V` are compromised, and the IV can be biased in an unknown
direction.

**How to handle it (menu, in increasing order of rigor — recommend doing 2+3+4):**

1. **Holding-period trimming.** Drop pairs with very short gaps (flips, distressed
   churn, possible non-arms-length) AND very long gaps (more cumulative renovation
   + index error). A common window is ~1–10 years; report sensitivity to the
   window. (Short-gap drop also guards against the same transitory shock
   contaminating both "sales," which would *reintroduce* the very error you're
   instrumenting away.)
2. **Permit / improvement flags.** Where building-permit data exist, **drop or flag
   parcels with a major permit between the two sales.** Nationally, permits are
   patchy; use the CoreLogic-internal proxy: a **large jump in assessed
   improvement value / living-area / bed-bath count between vintages** as a
   renovation flag, and drop those parcels. (This is the scalable national analog
   of Case-Shiller's renovation deletion.)
3. **Bounding.** Re-estimate on the "clean" (no-permit, no-characteristic-change)
   subsample and report the elasticity as a **bound** relative to the full
   repeat-sales sample. If the IV elasticity is stable across the renovation
   trimming, the threat is empirically small.
4. **Overid test.** With both a prior and a subsequent sale as instruments, a
   **Hansen J overid test** has power against renovation contamination: if one sale
   is post-renovation and the other is not, the two instruments disagree about `V`
   and J rejects. A non-rejection is reassuring (necessary, not sufficient).

**Direction-of-bias note to pre-empt a referee.** State explicitly which way
uncorrected renovation bias would push your *regressivity* estimate, given that
renovations are more common at the high end vs. low end of the price distribution —
this is an empirical question you should answer in the data, not assert.

---

## 5. Is the hedonic-predicted-value instrument valid? (It is not — and why your ~0 is the tell)

**No — the hedonic-characteristics-predicted-value instrument is invalid here, on
the exclusion restriction, for exactly the shared-information reason you suspect.**

**The mechanism of the violation.** Your outcome is the assessment ratio
`A/P = (assessed value)/(price)`. The assessor produces `A` by a **mass-appraisal
model that uses the same recorded hedonic characteristics `X`** (sqft, beds, baths,
year built, lot size, etc.). A hedonic prediction `V̂ = X·β̂` is therefore
mechanically correlated with the **numerator `A`** of your outcome — not only
through the latent value `V` but through the *shared inputs*. The exclusion
restriction requires the instrument to affect the outcome *only through the
endogenous regressor* (here, true value / price). A hedonic `V̂` affects the
outcome **through `A` directly**, so `cov(V̂, structural error) ≠ 0`. **Exclusion
fails.**

This is the standard "instrument is a direct input to the outcome" violation: the
instrument and the outcome share a common cause (`X`) by construction, because the
*assessor and your instrument read from the same characteristics file*.

**Why your ~0 estimate is consistent with this.** If `V̂` is invalid and correlated
with `A`, the IV is pulled toward the OLS-of-`A`-on-`V̂` relationship, which —
because `A` tracks `V̂` almost mechanically — drives the *recovered* regressivity
toward "no division bias" / coefficient ≈ 0. **A ~0 from an invalid instrument is
not evidence that division bias is absent; it is the fingerprint of exclusion
failure.** Do not interpret the hedonic-IV ~0 as a substantive result.

**Why repeat-sales prices do NOT share this defect.** The transitory error of a
*different transaction* (the prior/subsequent arms-length sale) is generated by the
idiosyncratic match of a *different buyer-seller pair at a different date* — it does
not enter the assessor's information set for the focal-date assessment in the way
`X` does. Conditional on true value `V`, `P_other`'s transitory noise is plausibly
orthogonal to the focal-sale assessment error. That is the whole point: you want an
instrument correlated with `V` but **not** with the focal sale's transitory noise
*and not a direct input to `A`*. The other-period price satisfies this; the hedonic
prediction does not. (Caveat: if the assessor *also* uses recent sales of the same
parcel to set `A` — e.g. an acquisition-value or recent-sale-chasing system —
then `P_other` could leak into `A` and the exclusion weakens. Check the
assessment-regime rules; in pure mass-appraisal cyclical systems this leakage is
second-order, but in acquisition-value states like CA it is first-order. **Flag for
sample restriction.**)

**Recommendation.** Drop the hedonic-predicted-value instrument from the main
specification. If you want to keep it anywhere, use it only as a **deliberately
"bad" instrument in an over-identification / falsification exhibit** that *shows*
exclusion failure (e.g., a comparison where the hedonic IV and the repeat-sales IV
diverge and the Hansen J rejects when the hedonic IV is added) — that turns your ~0
from an embarrassment into evidence for your identification argument.

---

## 6. Other JPubE-referee pitfalls to pre-empt

### (a) LATE interpretation of the repeat-sales subsample (selection)

**This is your most serious threat and a referee will lead with it.** The IV is
estimated only on parcels that **sell at least twice (ideally three times)** within
the panel. Homes that resell are a **non-random selection** of the stock.

**Verified precedent.** Gatzlaff & Haurin (1997, *JREFE* 14(1-2):33–50; and 1998,
*J. Urban Economics*) show that repeat-sales samples are selected and that the
selection is **correlated with the business cycle** — repeat-sales indices diverge
systematically from selection-corrected (Heckman-type) indices. The broader
literature (e.g., Melser 2023, *Oxford Bulletin*; Meese-Wallace) confirms
frequently transacting homes are not representative.

**What it means for you.** Your IV elasticity is a **LATE for the population of
frequently transacting homes**, not the ATE for all parcels. Frequently
transacting homes likely skew toward starter homes, investor-held units,
high-turnover neighborhoods — plausibly *lower* in the price distribution, which is
exactly where regressivity is most acute. So the LATE could over- or under-state
the population regressivity in a signable direction.

**Mitigations (do at least two):**
1. **Characterize the selection.** Compare the repeat-sales subsample to the full
   transaction sample on price decile, tract income, turnover, property type — show
   the reader exactly who is in the LATE.
2. **Reweight** the repeat-sales sample to the full-sample distribution of
   observables (price decile × tract × year) and report the reweighted IV.
3. **Selection-corrected estimate.** A Gatzlaff-Haurin / Heckman-style first-stage
   selection equation (probability of resale) as a robustness check.
4. **Frame honestly.** State up front that the IV identifies a LATE for resold
   homes and argue (with the §6a characterization) why it bounds or informs the
   population object. Do not over-claim an ATE.

### (b) Weak instruments at N in the millions — a non-issue, but report it

**Verified reasoning.** Weak-instrument concern is about the *concentration
parameter* (instrument strength × sample size), not sample size alone — but with
(i) a single endogenous regressor, (ii) one or two strong instruments (the
other-period sale is mechanically *highly* correlated with true value — first-stage
R² will be large), and (iii) N in the millions, the first-stage F will be in the
thousands and weak-ID is **not a live concern**. The Stock-Yogo machinery is for
*fixed, possibly weak* instruments; it does not flag a strong single instrument at
huge N.

**What to do anyway:** report the **first-stage F (or Kleibergen-Paap rF for the
clustered/robust case)** so the referee sees it, and note that it vastly exceeds
any conventional threshold. One sentence closes the issue. (Do **not** invent a
many-weak-instruments problem you don't have; you have one or two strong
instruments, not hundreds of weak ones.)

### (c) Clustering

Cluster standard errors at the level of the **assessment jurisdiction** (county or
assessing unit), or **jurisdiction × year** if you have within-jurisdiction
serial-correlation concerns. Rationale: assessment models, reassessment timing, and
index deflation are common shocks within a jurisdiction; OLS/IV residuals are
correlated within jurisdiction. With millions of obs and thousands of clusters,
cluster-robust inference is well-behaved (no few-clusters problem). Report the
number of clusters. (Two-way clustering jurisdiction × year is a reasonable
robustness column.)

### (d) Report the level-on-level spec alongside the ratio spec

**Yes — report `log(assessed) = α + β·log(price)` and test `H0: β = 1`, alongside
the ratio specification.** Reasons:

1. **It is the field's preferred form.** Cheng (1974) reframed the vertical-equity
   test from the Paglin-Fogarty *intercept* test (`A = a + bP`, test `a≠0`) to the
   **log-log slope** test (`log A = a + b log P`, regressive iff `b < 1`). This is
   the direct ancestor of the modern specification and the IAAO review lists the
   Cheng test in its recommended suite.
2. **It is less mechanically biased than the ratio form.** Putting price on *both*
   sides (ratio LHS denominator + RHS) is the worst case for division bias; the
   level-on-level form has price only on the RHS, so the EIV/division problem is the
   standard attenuation toward `β = 1` (cleaner to reason about, and exactly what
   the repeat-sales IV corrects).
3. **The two specs are algebraically linked** (`log(A/P) = log A − log P`, so the
   ratio-on-log-price slope = `β − 1`), so reporting both costs nothing and lets a
   referee check internal consistency. A regressivity finding should survive in
   **both** the ratio slope (< 0) and the level slope (< 1) — and crucially, your IV
   should move *both* toward the no-regressivity null (slope → 0 / β → 1) if division
   bias is what's driving the OLS result.

**Recommendation:** make the level-on-level IV (`log A` on instrumented `log P`,
test `β=1`) the **headline identification table**, and present the ratio-on-log-price
slope as the translation that connects to Berry's −0.37. This is the most
referee-proof framing and directly answers McMillen & Singh's "the regression
statistic is unreliable" critique by showing the *corrected* statistic.

---

## Consolidated recommendations

1. **Headline spec:** `log(assessed) = α_j + β·log(price)` with jurisdiction FE,
   `log(price)` instrumented by deflated prior + subsequent arms-length sale(s);
   test `β = 1`. Report ratio-on-log-price (`β−1`) as the bridge to Berry.
2. **Instrument:** deflated other-period sale(s); use both prior and subsequent
   when available → over-identified → run Hansen J.
3. **Deflator:** FHFA annual HPI, finest reliable geography via a tract→ZIP→county→
   CBSA fallback ladder; disclose purchase-only vs all-transactions choice.
4. **Renovation defense:** holding-period trim (~1–10 yr), drop permit/large-
   characteristic-change parcels, report no-renovation-subsample bound, lean on the
   Hansen J.
5. **Drop the hedonic-predicted-value instrument** from the main spec (exclusion
   fails via shared characteristics); optionally repurpose it as a falsification
   exhibit that *demonstrates* the exclusion failure.
6. **Selection (LATE):** characterize the resale subsample, reweight to the full
   sample, and frame the estimate as a LATE for frequently transacting homes; offer
   a Gatzlaff-Haurin selection-corrected robustness column.
7. **Inference:** cluster at jurisdiction (or jurisdiction×year); report first-stage
   F to dispose of weak-ID in one sentence.
8. **Robustness to the McMillen-Singh critique:** alongside the IV elasticity,
   report at least one distribution-based statistic (Gini or Suits gap) and show the
   regressivity conclusion is qualitatively the same.
9. **Acquisition-value caveat:** in states where the assessor chases recent sales
   (e.g., CA Prop-13 acquisition-value regimes), the other-period sale can leak into
   `A` and weaken exclusion — restrict or separately analyze those states.

---

## Claims I could NOT verify (read before citing)

- **[UNVERIFIED-PRIMARY] McMillen & Singh (2023) exact wording** of the bias source
  (functional-form mismatch vs. noise) and the precise definition of their three
  distribution tests — ScienceDirect full text 403'd; triangulated from the
  abstract, Lincoln working-paper page, and the IAAO 2023 task-force review. Open
  the local/Lincoln PDF to confirm before quoting.
- **[UNVERIFIED-PRIMARY] Clapp (1990) estimator details** (exact form of the
  variable switch and which second-appraisal instrument) — JREFE PDF not opened;
  triangulated from a review snippet stating he "switches dependent/explanatory
  variables and uses an instrumental variable in place of lnA." Confirm the precise
  construction before describing it as your direct precedent.
- **[UNVERIFIED] Whether Berry (2021) or Amornsiripanitch (2022) already use
  repeat-sales / prior-sale IV.** Both PDFs returned as un-parseable binary /
  403. My working claim ("neither uses repeat-sales IV") is inferred from secondary
  descriptions, not confirmed from their text. **This bears directly on your novelty
  claim — verify by reading both local PDFs (`docs/berry2021.pdf` and the
  Amornsiripanitch Philly Fed WP) before asserting novelty in the manuscript.**
- **[UNVERIFIED] No published assessment-regressivity paper uses the prior/subsequent
  sale as the true-value instrument.** This is an absence-of-evidence claim from the
  searches I ran (not exhaustive). A targeted `/lit-review` on "errors-in-variables
  vertical equity instrument repeat sales" should confirm before claiming first-mover.
- **[UNVERIFIED-PRIMARY] FHFA tract-level annual index availability and suppression
  rules** — confirmed FHFA publishes county/ZIP/tract annual series from the FAQ and
  experimental-local-HPI FAQ, but the exact tract-level coverage, vintages, and
  suppression thresholds for your sample years should be checked against the actual
  FHFA data files before building the deflation ladder.

---

## Sources

- [McMillen & Singh 2023, *J. Housing Economics* — ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S1051137723000372)
- [McMillen & Singh 2023 — Lincoln Institute working-paper page](https://www.lincolninst.edu/publications/working-papers/measures-vertical-inequality-in-assessments/)
- [Lincoln Institute — Vertical Equity App / measures overview](https://www.lincolninst.edu/publications/articles/2023-12-vertical-equity-app-tax-assessments-tool/)
- [IAAO Statistical Tools & Measures Task Force (2023), *JPTAA* — review of vertical-equity measures](https://researchexchange.iaao.org/jptaa/vol20/iss2/7/)
- [Quintos (2020), Gini measure for vertical equity, *JPTAA*](https://researchexchange.iaao.org/jptaa/vol17/iss2/2/)
- [Krupa (2014), housing crisis & vertical equity, *Public Finance Review* (cites Clapp 1990 IV)](https://ideas.repec.org/a/sae/pubfin/v42y2014i5p555-581.html)
- [Hodge, McMillen, Sands & Skidmore (2017), Detroit assessment inequity, *Real Estate Economics*](https://onlinelibrary.wiley.com/doi/abs/10.1111/1540-6229.12126)
- [Gatzlaff & Haurin (1997), Sample Selection Bias and Repeat-Sales Index Estimates, *JREFE* — RePEc](https://ideas.repec.org/a/kap/jrefec/v14y1997i1-2p33-50.html)
- [Gatzlaff & Haurin (1997) — SSRN](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=9274)
- [Melser (2023), Selection Bias in Housing Price Indexes, *Oxford Bulletin of Economics and Statistics*](https://onlinelibrary.wiley.com/doi/full/10.1111/obes.12534)
- [Repeat-sales + IV stream-restoration valuation, *Env. & Resource Economics* (2021)](https://link.springer.com/article/10.1007/s10640-021-00575-9)
- [FHFA House Price Index — main data page](https://www.fhfa.gov/data/hpi)
- [FHFA HPI FAQ (methodology, geographies)](https://www.fhfa.gov/faqs/hpi)
- [FHFA experimental local HPI FAQ (ZIP/tract/county annual indices)](https://www.fhfa.gov/sites/default/files/documents/bdl_faqs_local_hpis.pdf)
- [St. Louis Fed — A Closer Look at House Price Indexes (FHFA vs Case-Shiller)](https://www.stlouisfed.org/publications/regional-economist/july-2011/a-closer-look-at-house-price-indexes)
- [Case-Shiller index overview (Wikipedia — renovation deletion, interval weighting)](https://en.wikipedia.org/wiki/Case%E2%80%93Shiller_index)
- [Amornsiripanitch (2022), Why Are Residential Property Tax Rates Regressive?, Phila Fed WP 22-02](https://www.philadelphiafed.org/-/media/frbp/assets/working-papers/2022/wp22-02.pdf)
- [Berry (2021), Reassessing the Property Tax (Yale-hosted PDF)](https://law.yale.edu/sites/default/files/area/center/corporate/spring2022_paper_berrychristopher_2-24-22.pdf)
- [Stock & Yogo / weak-instrument testing — NBER TWP 0284](https://www.nber.org/system/files/working_papers/t0284/t0284.pdf)
- [CCAO assessr — PRD definition and interpretation](https://ccao-data-science---modeling.gitlab.io/packages/assessr/reference/prd.html)
