# Literature Review — Property Tax Assessment Regressivity (DRAFT)

> **STATUS: DRAFT for researcher review.** Every cited paper below was grounded
> via WebSearch/WebFetch (June 2026), not from memory. Verified entries are in
> `lit_review_regressivity.bib`. Items that could not be verified to >90%
> confidence are quarantined in the **UNVERIFIED** section at the bottom and are
> NOT in the `.bib`. Before this enters the manuscript, run `/verify-claims` on
> the numeric claims (effective-rate gaps, decomposition shares, elasticities)
> and `/validate-bib`.

**Project:** `01_property_tax_regressivity` · **Researcher:** Saani Rawat (Marquette)
**RQ anchor:** Which *mechanism* — information decay (reassessment-cycle length),
information-acquisition cost (transaction density), assessor institutional
incentives, appeals technology, or transaction-frequency staleness — drives the
within-jurisdiction regressivity that Berry (2021) documents (assessment-ratio
elasticity ≈ −0.37; our Phase-1 replication ≈ −0.42 on a 2007–2010 window)?

---

## Cluster 1 — Foundational vertical-inequity / sales-ratio literature

This is the measurement substrate. The field's core empirical object is the
**assessment ratio** A/P (assessed value over sale price) and whether it falls
with P (regressivity / vertical inequity) within a jurisdiction.

**Origins — sales-ratio studies.** `oldman1965assessment` (Oldman & Aaron, *NTJ*
1965) is the canonical early sales-ratio study of a single jurisdiction
(Boston), establishing the assessment-ratio-vs-value diagnostic that the whole
literature inherits. `paglin1972equity` (Paglin & Fogarty, *NTJ* 1972) gave the
field its first formal conceptual framework: regress assessed value A on price P
and test whether the *intercept* differs from zero as the marker of
inequity — the "A = a + bP, test a≠0" specification.

**The measurement war.** Paglin–Fogarty's intercept test was quickly contested.
`cheng1974property` (Cheng, *Public Finance* 1974) reframed the test in
logs — regress log A on log P and test whether the *slope* differs from one — the
direct ancestor of Berry's and our log-log elasticity specification.
`clapp1990new` (Clapp, *JREFE* 1990) showed both prior tests are biased because
true market value is unobservable (the regressor P is an error-laden proxy for
V), and proposed a 2SLS correction using a second appraisal as an instrument; on
52 Connecticut towns it removes a substantial part of the bias.
`sirmans1995vertical` (Sirmans, Diskin & Friday, *NTJ* 1995) is the most-cited
synthesis/critique of the competing vertical-inequity specifications and is the
standard "which test should you run" reference.

**The modern measurement reckoning.** `mcmillen2023measures` (McMillen & Singh,
*J. Housing Economics* 2023) is the most important recent methodological
paper for *us*: it shows that the standard regression-based regressivity
coefficient — exactly the −0.37/−0.42 elasticity Berry reports and we
replicate — carries a **mechanical bias toward finding regressivity even when
none is present**, because assessed value is itself a noisy estimate of price.
They propose distribution-based alternatives (difference in Gini coefficients, a
Suits index, and a nonparametric kernel-density test). `quintos2020gini`
(Quintos, *JPTAA* 2020) is the originating Gini-based vertical-equity measure.

**Practitioner standards (the IAAO toolkit).** `iaao2013ratio` (IAAO *Standard on
Ratio Studies*, 2013) is the assessing profession's authoritative measurement
manual: it defines the **coefficient of dispersion (COD)** for horizontal
uniformity (residential target 5–15%) and the **price-related differential
(PRD)** for vertical equity (target 0.98–1.03), with the **price-related bias
(PRB)** as a regression-based supplement. `iaao2023review` (IAAO Statistical
Tools and Measures Task Force, *JPTAA* 2023) benchmarks these measures against
each other on simulated data and motivates the newer Vertical Equity Indicator.

### Gap relative to our RQ

This cluster is almost entirely **descriptive/measurement** — it asks *whether*
assessments are regressive and *how to measure it cleanly*, never *which
institutional or informational mechanism produces it*. The actionable warning
for us is `mcmillen2023measures`: our headline −0.42 may be partly mechanical.
**Implication for the project:** the mechanism decomposition should be expressed
in a way that is robust to the McMillen–Singh critique — e.g., report whether
each mechanism moves a *distribution-based* statistic (Gini/Suits gap), not only
the OLS slope, so a referee cannot dismiss the entire decomposition as an
artifact of regressing on a noisy price. None of these papers decomposes
regressivity into mechanism shares; that is open ground.

---

## Cluster 2 — The current wave (Berry 2021 and the modern revival)

The revival is driven by the arrival of **national parcel-level data** (CoreLogic
Tax / public-records assembly), which let researchers run the within-jurisdiction
test at national scale rather than one county at a time.

**The anchor.** `berry2021reassessing` (Berry, U. Chicago Harris WP / SSRN 2021)
documents that within a jurisdiction the assessment ratio falls with sale price
nationally; bottom-decile homes face roughly **twice** the effective rate of
top-decile homes in the same jurisdiction; the within-jurisdiction tax-rate
elasticity ≈ **−0.37** on ~26M residential sales 2007–2017. Berry attributes the
pattern primarily to **limitations in assessors' data and methods** (an
information story) rather than to political economy — a claim that is asserted
more than decomposed, which is precisely the wedge for this project.
`berry2024dejure` (Berry, *Public Budgeting & Finance* 2024) is the natural
follow-up: across 74 large US cities it shows effective ("de facto") rates
diverge from statutory ("de jure") rates mainly because of **lags in estimated
values** — a direct, named pointer at the reassessment-staleness mechanism (our
H2/H6).

**Convergent national estimates.** `amornsiripanitch2022why` (Amornsiripanitch,
Philadelphia Fed WP 22-02, 2022) independently confirms the result on CoreLogic
Tax (~150M parcels): owners of inexpensive homes pay ~**50% higher** effective
rates, and — critically for us — it *attempts a decomposition*, attributing about
**60%** of the residual regressivity to assessors' flawed valuation methods
(ignoring priced characteristics) and **40% to infrequent reappraisal**. This is
the closest existing work to our decomposition goal and the paper we must most
sharply differentiate from (see Positioning). `mcmillen2020assessment` (McMillen
& Singh, *JREFE* 2020) provides the careful methodological companion to the
national-scale revival.

**The racial-equity branch.** `avenancioleon2022assessment` (Avenancio-León &
Howard, *QJE* 2022) is the highest-profile paper in the wave: holding
jurisdiction and statutory rate fixed, Black and Hispanic owners face a **10–13%
higher** assessment-driven tax burden; just over half is *between*-neighborhood.
Their stated mechanism — assessments are **less sensitive to neighborhood
attributes than market prices are** — is an information/mass-appraisal story that
parallels Berry's, and they document that **appeals behavior and outcomes differ
by race** (a bridge to our appeals mechanism, H5).

**The Detroit / legal-scholarship branch.** `hodge2017assessment` (Hodge,
McMillen, Sands & Skidmore, *Real Estate Economics* 2017) is the rigorous
quantile-regression treatment of Detroit's collapsed-market over-assessment and
regressivity. `atuahene2019taxed` (Atuahene & **Berry**, *UC Irvine Law Review*
2019) ties over-assessment to tax foreclosures — estimating ~10% of Detroit tax
foreclosures, and ~25% in the bottom price quintile, were caused by
unconstitutional over-assessment. `schleicher2025your` (Schleicher, *Harvard
Journal on Legislation* 2025) is the recent legal synthesis of the whole
regressivity literature.

**Capitalization and property-class extensions.** `hodge2025double` (Hodge,
Komarek & McAllister, *Public Finance Review* 2025) shows assessment inequity is
**capitalized**: over-assessed homes sell at a ~13% discount, under-assessed at a
~10% premium — so regressivity compounds into wealth effects. `cai2025evaluating`
(Cai & Wiley, *Real Estate Economics* 2025) shows regressivity varies sharply
**across property classes** in Cook County and that the **appeals process
exacerbates** regressivity for commercial/industrial classes — direct evidence
for the appeals mechanism (H5).

### Gap relative to our RQ

The wave has firmly established *that* regressivity is real, national, racially
patterned, capitalized, and consequential (foreclosures). On **mechanism**, two
papers actually attempt a decomposition — `amornsiripanitch2022why`
(60% methods / 40% reappraisal) and, descriptively, `avenancioleon2022assessment`
(neighborhood-insensitivity). But neither (a) compares the **full menu of five
mechanisms** we target — they omit assessor *institutions* (elected/appointed),
appeals *as a wealth-gated technology*, and transaction-frequency staleness as
distinct channels — nor (b) ties the decomposition to a **structural model that
permits counterfactual reforms** (shorten cycles / costless appeals / appoint
assessors) and a **revenue-misallocation** object by decile. Amornsiripanitch's
split is reduced-form and partial-R²-flavored; it is the benchmark to beat, not a
substitute for a structural decomposition.

---

## Cluster 3 — Mechanisms (cycles, caps, appeals, institutions, exemptions)

Each candidate mechanism in our RQ has its own (mostly older or single-state)
empirical literature. These are the papers that license each hypothesis.

**Reassessment cycles & staleness (H2, H6).** `mikesell1980property` (Mikesell,
*Public Finance Quarterly* 1980) is the foundational cross-jurisdiction study of
**reassessment-cycle length** and its effect on uniformity and effective rates —
directly the H2 channel, and the precedent for using statutory cycle length as
variation. `hou2023assessment` (Hou, Ding, Schwegman & Barca, *JPAM* 2023 / Phila
Fed WP 21-43) is the modern causal counterpart: a difference-in-differences
around Philadelphia's 2014 Actual Value Initiative shows **more frequent
reassessment improves equity**, with heterogeneous effects across value and
neighborhood. Together these are the strongest external support that
cycle-length/staleness is a *causal* driver — which our border-MSA design (H2)
and transaction-frequency mediator (H6) aim to identify nationally.

**Institutions — elected vs. appointed assessors (H4).** `bowman1989elected`
(Bowman & Mikesell, *NTJ* 1989) is the seminal elected-vs-appointed-assessor
study (Virginia): the sign favors appointed assessors but the effect on
uniformity is not statistically significant — i.e., the institutional channel is
*hypothesized but underpowered* in the prior literature, leaving national-scale
identification open. `ross2012interjurisdictional` (Ross, *Land Economics* 2012)
is the key modern study of **interjurisdictional institutional determinants** of
regressivity and the closest precedent for treating institutions as the
explanatory variable rather than a control.

**Appeals technology (H5).** `mcmillen2013effect` (McMillen, *Real Estate
Economics* 2013) shows nonparametrically how the **appeals process reshapes the
assessment-ratio distribution** — the methodological template for measuring
appeals' effect on regressivity. `doerner2014empirical` (Doerner & Ihlanfeldt,
*JPTAA* 2014) finds appeals reductions are not well-targeted to true errors and
that the probability of a successful reduction is **highest in majority-white
neighborhoods** — the wealth/access-gated appeals story underlying H5.
`cai2025evaluating` (also Cluster 2) provides recent evidence that appeals
*amplify* regressivity for some classes. These collectively justify modeling
appeals as a wealth-elastic technology (our α₂).

**Assessment limits / caps & exemptions (acquisition-value systems).**
`krupa2014housing` (Krupa, *Public Finance Review* 2014) studies vertical equity
under a market-value assessment system through the housing crisis (Indiana),
isolating how market downturns interact with assessment lags to produce
regressivity — the mechanism our 2007–2010 crash-window replication is most
exposed to (see replication report's "housing-bust" explanation for our −0.42 vs
Berry's −0.37). `ihlanfeldt2022homestead` (Ihlanfeldt & Rodgers, *NTJ* 2022)
shows **homestead exemptions can offset** regressive assessment and even flip the
net tax to progressive in most Florida counties — i.e., a statutory feature that
can *mask or counteract* the assessment-driven regressivity we measure, and a
necessary control when comparing jurisdictions.

### Gap relative to our RQ

The mechanism literatures are **siloed and mostly single-state**: cycles
(Mikesell; Hou et al. — Philadelphia), institutions (Bowman–Mikesell — Virginia;
Ross), appeals (McMillen; Doerner–Ihlanfeldt — Florida/Chicago), caps/exemptions
(Krupa — Indiana; Ihlanfeldt–Rodgers — Florida). **No paper estimates all
channels in one national framework**, so their *relative* magnitudes are unknown.
Several are descriptive or underpowered on the very channel they study (e.g.,
Bowman–Mikesell's null on institutions). This is the precise opening for a
structural model estimated on national CoreLogic data that puts cycles, density,
institutions, appeals, and transaction-frequency on a common scale and reports
**which dominates** — and what each counterfactual reform buys.

---

## Positioning — where the mechanism-decomposition contribution sits

The literature has converged on three facts: regressivity is **real and national**
(Berry 2021; Amornsiripanitch 2022; McMillen & Singh 2020), it is **racially
patterned and capitalized** (Avenancio-León & Howard 2022; Hodge et al. 2025),
and it is **measured with a known upward bias** by the standard regression
(McMillen & Singh 2023). On *mechanism*, the field has only two partial moves:
Berry's informal "data-and-methods" attribution, and Amornsiripanitch's
reduced-form 60/40 split (valuation methods vs. infrequent reappraisal). Neither
puts the **full menu** — reassessment-cycle decay, transaction-density
information cost, assessor institutions, wealth-gated appeals, and
transaction-frequency staleness — on a **common, comparable scale**, and neither
ties the decomposition to **counterfactual policy reforms** or a **dollar
revenue-misallocation** object by price decile.

This project's contribution is the structural **decomposition + counterfactual**
layer that sits on top of the now-settled descriptive finding. Three
differentiators are defensible against the closest prior work:

1. **Vs. Amornsiripanitch (the benchmark to beat):** we add the three channels he
   omits (institutions, appeals-as-wealth-technology, transaction-frequency
   staleness) and replace a reduced-form variance split with a structural model
   whose primitives map to *named reforms* (annual reassessment, costless
   appeals, appointed assessors). His 60/40 is the headline number our structural
   estimates must speak to directly.
2. **Vs. Berry:** we replicate his descriptive result (done — −0.42 with caveats)
   but convert his informal mechanism claim into an estimated, falsifiable
   decomposition, and quantify the **fiscal redistribution** (who subsidizes
   whom, by decile) that he leaves implicit.
3. **Vs. the siloed mechanism literatures:** we unify channels each previously
   studied in one state into a single national estimation, recovering their
   *relative* magnitudes — which none can do alone.

**Robustness obligation flagged by the review:** because `mcmillen2023measures`
shows the OLS regressivity slope is mechanically biased, the decomposition should
be shown to hold (qualitatively) under at least one distribution-based regressivity
statistic (Gini/Suits gap), so the mechanism shares cannot be dismissed as an
artifact of the noisy-price regression. This is cheap insurance against the most
likely referee objection and should be added to the Phase-2/Phase-3 spec.

---

## UNVERIFIED — needs `/verify-claims` before any use

These surfaced during search but could **not** be verified to >90% confidence on
all bibliographic fields, or are claims I am carrying with a caveat. They are
**not** in the `.bib`. Do not cite until resolved.

- **Berry & Wang (2024), "Property Tax Assessment and Housing Market Cycles"**
  (Syracuse Maxwell/CPR property-tax webinar series). Listed in the project spec
  (C2) as PARTIAL — the hosting PDF was binary at verification time and I could
  not confirm the exact title, venue, or year beyond the filename
  "berry-and-wang-2024". *Unsure:* exact title, publication status (working paper
  vs. published), year. Worth chasing for the H6 transaction-frequency / housing-
  cycle angle if it exists.
- **Berry 2024 (*Public Budgeting & Finance*, "De jure and de facto…") — page
  range only.** The paper itself is VERIFIED and in the `.bib` (vol 44, no 4,
  2024, DOI 10.1111/pbaf.12382); I could **not** retrieve confirmed **page
  numbers**, so the page field is omitted from the entry rather than guessed.
  `/validate-bib --semantic` or a publisher lookup should fill `pages`.
- **Hou, Ding, Schwegman & Barca — *JPAM* publication year/volume/pages.** The
  DOI (10.1002/pam.22555) and authorship are VERIFIED and the entry is in the
  `.bib`; I tagged year 2023 but could **not** confirm the final
  volume/issue/pages (the abstract page was paywalled at 402/Payment Required).
  The Phila Fed WP 21-43 version is independently confirmed. Confirm the JPAM
  volume/issue/pages before manuscript use.
- **Schleicher 2025 (*Harvard Journal on Legislation*, 62.1) — page range.**
  Author/title/venue/volume were CoVe-verified earlier in the project spec (C5,
  PASS); the article PDF was binary on re-fetch here, so I could not pull a
  confirmed **page range**. Entry is in the `.bib` without `pages`; fill before use.
- **Cheng (1974), *Public Finance/Finances Publiques* 29(3):268–284 — page
  range.** Author/title/year/venue are well-attested across multiple secondary
  sources (it is a heavily cited classic) and the entry is in the `.bib`, but I
  did **not** open a primary source confirming the exact 268–284 pagination;
  treat the page field as secondary-source-derived pending a library check.
- **Cai & Wiley (2025/2026) — year ambiguity.** Confirmed in *Real Estate
  Economics* (DOI 10.1111/1540-6229.70051, Early View); one search snippet said
  2025, another 2026. Entry carries 2025 + `note = {Early View}`. Confirm the
  assigned issue year at final-version stage.

---

### Verification log (how each `.bib` entry was grounded)

| Key | Grounding | Confidence |
|---|---|---|
| oldman1965assessment | NTJ vol 18(1):36–49, DOI 10.1086/NTJ41791421 (UChicago Press) | High |
| paglin1972equity | NTJ 25(4):557–565, DOI 10.1086/NTJ41791839 | High |
| cheng1974property | Public Finance 29(3):268–284 (secondary sources; widely cited) | Med-High |
| mikesell1978property | Public Finance Q. 6(1):53–65, DOI 10.1177/109114217800600103 (SAGE) | High |
| clapp1990new | JREFE 3(3):233–249, DOI 10.1007/BF00216188 (Springer) | High |
| sirmans1995vertical | NTJ 48(1):71–84, DOI 10.1086/NTJ41789124 | High |
| quintos2020gini | JPTAA 17(2), DOI 10.63642/1357-1419.1225 (IAAO) | High |
| iaao2013ratio | IAAO Standard on Ratio Studies, approved Apr 2013 (iaao.org) | High |
| iaao2023review | JPTAA 20(2), 2023, DOI 10.63642/1357-1419.1265 | High |
| mcmillen2023measures | J. Housing Econ. 61:101950, DOI 10.1016/j.jhe.2023.101950 | High |
| berry2021reassessing | U. Chicago Harris / SSRN 3800536, March 2021 | High |
| mcmillen2020assessment | JREFE 60(1):155–169, DOI 10.1007/s11146-019-09715-x (RePEc) | High |
| avenancioleon2022assessment | QJE 137(3):1383–1434, DOI 10.1093/qje/qjac009 | High |
| amornsiripanitch2022why | Phila Fed WP 22-02, 2022 (DOI 10.21799/frbp.wp.2022.02) | High |
| hodge2017assessment | Real Estate Econ. 45(2):237–258, DOI 10.1111/1540-6229.12126 | High |
| atuahene2019taxed | UC Irvine Law Review 9(4):847–886, 2019 | High |
| schleicher2025your | Harvard J. on Legislation 62(1), Winter 2025 (pages TBD) | High (pages unconfirmed) |
| berry2024dejure | Public Budgeting & Finance 44(4), 2024, DOI 10.1111/pbaf.12382 (pages TBD) | High (pages unconfirmed) |
| cai2025evaluating | Real Estate Econ., DOI 10.1111/1540-6229.70051, Early View | High (issue-year TBD) |
| hodge2025double | Public Finance Review 53(6):752–785, DOI 10.1177/10911421241280456 | High |
| mikesell1980property | Public Finance Q. 8(1):23–37, DOI 10.1177/109114218000800102 | High |
| hou2023assessment | JPAM, DOI 10.1002/pam.22555; also Phila Fed WP 21-43 | High (JPAM vol/pages TBD) |
| ross2012interjurisdictional | Land Economics 88(1):28–42, 2012 (RePEc/JSTOR) | High |
| bowman1989elected | NTJ 42(2):181–189, 1989 (RePEc + UChicago Press) | High |
| mcmillen2013effect | Real Estate Econ. 41(1):165–191, DOI 10.1111/j.1540-6229.2011.00326.x | High |
| doerner2014empirical | JPTAA 11(4), 2014; FSU WP wp2012_01_01 | High |
| ihlanfeldt2022homestead | NTJ 75(1):7–31, DOI 10.1086/717587 | High |
| krupa2014housing | Public Finance Review 42(5):555–581, DOI 10.1177/1091142113496132 | High |

_Grounded June 2026 via WebSearch/WebFetch. Several full-text fetches were
blocked by paywalls (Springer/Wiley/UChicago 303/402/403); for those, metadata
was triangulated from RePEc, journal tables-of-contents, and DOI resolvers
rather than the article body — flagged above where a field remains unconfirmed._
