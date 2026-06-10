# Methods Referee Report (agent) — 2026-06-10

**Verdict:** Major Revision, composite 59/100 (capped by 2 failed sanity checks: pre-trends not shown; single-treated-cluster inference). Bunching design called "the paper's crown jewel"; replication package praised.

## CRITICAL
- **C1 single treated cluster:** all Prop 19 SEs (CRVE by state) invalid with CA as only treated unit → permutation/placebo-state inference required. → **ADDRESSED: 07_referee_checks.R permutation inference (volume DiD fam/market/net + estate-seller test); text reports permutation p-values; T4 note added.**
- **C2 interspousal/co-owner retitling contaminates family_person:** probe confirmed ~30% (CA 30.1%, rest 32.2%) exact same-person events. → **ADDRESSED: rebuild adds `family_retitle` class (b1_full==s1_full or b2_full==s1_full), excluded from all family headlines; all numbers recomputed.**
- **C3 release never directly observed:** → **ADDRESSED: 07 runs estate/trust-seller market-sale DiD (CA vs donors) + permutation — the direct supply test.**

## MAJOR (status)
- M1 placebo contamination (portability arm + release itself) + family-volume acyclicality → reframe 28% as bounds [~25%, 39%]; text updated.
- M2 COVID mortality deficit / out-migration confounds → acknowledged in threats; CDC WONDER control listed as revision item.
- M3 no pre-trends → event-study leads added (07); 2019-anchoring of bunching counterfactual disclosed.
- M4 pull-forward arithmetic → explicit bound added in text (33k excess vs 116k missing).
- M5 KM not apples-to-apples (composition, spell semantics, salability, trust-curve falsification) → caveat paragraph added; stratified KM deferred to revision (noted).
- M6 84k vs LAO 60-80k: flow-vs-flow wording fixed ("stock" removed); deeds-per-clip reconciliation stat added (07); "matches" → "same order of magnitude" with switcher logic caveat.
- M7 DDD equal-cyclical-exposure assumption (mortgage lock-in differs) → softened to "consistent with"; split by class deferred.

## MINOR (status)
- Broken T4 etable rows → fixed (dict-based, headers removed, inference note).
- "never offered for sale" → "never sold" (deeds observe sales, not listings) → fixed.
- Estate class size, probate routing → sentence added.
- New-construction in denominator → existing-stock ratio computed (07), footnoted.
- Others logged for revision.
