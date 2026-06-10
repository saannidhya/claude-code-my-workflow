# Session Log: Project 03 first-draft sprint

**Date:** 2026-06-09
**Goal:** From zero to full first manuscript draft of a new urban/real-estate paper
(top-5 general-interest target), per user instruction: new project under `projects/`,
use repo data + skills + review agents, no hallucinated numbers.

## Decisions

1. **Topic selection** (via data probes + /research-ideation + claim-verifier):
   intra-family (non-market) housing transfers + CA Prop 19 natural experiment.
   Rejected alternatives: turnover decline (crowded, Fonseca-Liu etc.), land values
   (Gyourko-Krimmel), climate (crowded), teardowns (prop snapshot limits).
2. **Window 2007–2023 (2024 partial):** OT density begins 2007 (probe: pre-2006
   negligible); truncates ~Aug 2024.
3. **Taxonomy frozen before regressions** (research_spec.md): market_sale /
   family_person (same-surname, conservative) / family_other / family_estate /
   family_trust (NEVER counted as family transfer) / other_nonarms / estate_noninterfam.
4. **fips/zip type normalization:** fips_code DOUBLE in some partitions, VARCHAR in
   others — lpad+regexp strip of `.0` (MEMORY.md join-bug lesson applied at source).
5. **Hazard censor date 2024-06-30** (conservative vs ~Aug truncation).
6. **Prop 19 designs:** bunching (CA 2019 baseline × rest-of-US growth counterfactual);
   volume DiD (2017-19 vs 2022-23, transition excluded); supply-release DiD/DDD on
   sold-within-24m (PRE cohorts 2017m1-2018m12, POST 2021m7-2022m6, market placebo);
   absentee composition DiD. Corporate buyers excluded from cohort analyses.
7. **Claim-verifier corrections adopted:** LAO 60-80k/yr figure attributed to LAO 2017
   (not ballot analysis); stepped-up basis = IRC §1014 (not TCJA); heirs'-property
   citations split into Dobbs & Johnson Gaither 2023 (JRSS) + Burnett &
   Winters-Michaud 2025 (ARER); novelty claims softened to "to our knowledge" + near-
   misses cited (Cotality/Delventhal 2026; LAO 2017).

## Key verified results so far

- Panel: 148,711,427 residential deed events (2007–2024), deduped.
- 2007–2023: market 71.08M; family broad 26.30M (ratio 0.370); trust 12.41M rising
  533k→973k/yr.
- Validation: family_person 91% zero price, 41% quitclaim, corp≈0; market median $224k.
- CA family:market ratio 0.73 (highest); national 0.37.
- Correlates: family share higher for older structures, senior-exempt parcels,
  lower value quintiles.
- Prop join match rate: 61.2% (current-snapshot prop vs 2017-23 events) — correlates
  conditional on match; documented.

## Open items

- 03_hazard + 04_prop19 running (bg task b07aw3xfj).
- Then: 05 tables, 06 figures, write manuscript, compile, r-reviewer + verify-claims
  + review-paper agents, fix, report.

## Update (post-analysis, ~20:30)

- Pipeline complete: 02 facts (61.2% prop match), 03 hazard (41s via exit-table KM),
  04 Prop 19 (after fixing two self-caught bugs: GROUP BY ALL missing clip key ->
  collapsed spells [added to MEMORY.md]; AVG(CASE..THEN 1 ELSE NULL) identically 1
  for absentee share).
- Headline causal results: bunching +33,048 (+28%) Nov20-Feb21; volume DiD -0.495
  (fam) vs -0.163 (market placebo) -> net -28.3% ~ 84k/yr; hazard DDD -0.71pp
  (selection signature, consistent with extensive-margin release); absentee -0.45pp n.s.
- KEY REFRAME: model rewritten around endogenous deed recording — the supply release
  shows up as missing family transfers (extensive margin), not faster conditional
  resale. Conditional hazard *fall* is the selection signature, informative about
  which transfers were excised.
- Manuscript: full draft written (everything from verified outputs), compiled clean
  23pp, 0 overfull, citations resolve.
- Review gate: 3 agents dispatched in parallel (r-reviewer; claim-verifier numeric
  audit of all 12 claim groups vs _outputs; methods-referee calibrated to top-5).

## Update (review cycle complete, 2026-06-10 ~01:15)

Three review agents returned; all findings triaged and the load-bearing ones fixed:
- Numeric audit: 11/12 PASS (fixed compounded-rounding 37->36%).
- r-reviewer (2 CRIT/8 MAJ/16 MIN) + methods referee (Major Revision, 59/100):
  full panel REBUILD with deterministic dedupe, month guard, ZIP normalization,
  family_retitle class (same-person co-owner changes; ~30% of old family_person),
  ADMINISTRATOR keyword fix, schema-drift assertions, prop-join dedupe + equality
  assertion, zero-cell guards, collinear DDD terms dropped.
- NEW 07_referee_checks.R: placebo-state permutation inference (volume fam p=.098
  rank 5/51, net p=.176, DDD p=.667), estate/trust-seller direct supply test
  (null in levels p=.71 and net-of-market p=.63 -> deferral interpretation),
  event-study leads (flat 2018-2021, -28%/-36% in 2022/23; 2017 +0.15 wobble
  disclosed), reconciliation stats (1.19 deeds/parcel; existing-stock ratio 0.30).
- Headline numbers (clean taxonomy): family broad 19.69M 2007-23; ratio 0.277
  (1 per 3.6 market sales); CA 0.61 = 2.3x national; bunching +28,866 (+31%);
  volume DiD -0.425 gross / -0.263 net (-35%/-23%); missing flow ~58k/yr, inside
  LAO 60-80k band (resolves referee M6 tension); 10y unsold 62% fam vs 58% mkt.
- Paper REFRAMED for inference honesty: bunching = primary causal evidence;
  cross-state estimates large but permutation-marginal; DDD/absentee reported as
  directionally consistent, not significant; supply release = deferred (direct
  test null), stated as falsifiable prediction.
- Final compile: 25pp, 0 overfull, 0 undefined citations, labels stable.
- Reviews archived in quality_reports/reviews/2026-06-10_*.md.
