# R Code Review (r-reviewer agent) — 2026-06-10

**Summary:** 2 CRITICAL, 8 MAJOR, 16 MINOR. Weighted-LPM≡micro-OLS equivalence, KM risk-set algebra, and the fixed GROUP BY ALL bug all verified clean.

## CRITICAL (status)
- C1 single-treated-cluster CRVE → **ADDRESSED** (permutation inference, 07_referee_checks.R).
- C2 non-deterministic dedupe (tied same-day records) → **ADDRESSED**: total ordering added (class, dtype, b1_full, s1_full tiebreakers); rebuild rerun.

## MAJOR (status)
- M1 month-00 dates leak into ym bins/bunching windows → **ADDRESSED**: `sale_month BETWEEN 1 AND 12` in 01 WHERE + post-build assertion.
- M2 TRY_CAST/union_by_name schema drift could NULL interfam silently → **ADDRESSED**: hard assertions (interfam NULL count = 0; interfam share in [0.10, 0.60]; ≥51 states).
- M3 ZIP leading zeros (Northeast) + 9-digit numeric ZIPs → **ADDRESSED**: length-aware lpad normalization for both ZIP fields.
- M4 prop join fan-out → **ADDRESSED**: prop_slim deduped to 1 row/clip + n_events equality assertion.
- M5 KM pooled nationally vs spec's state×year conditioning → caveat in text; stratified version deferred to revision.
- M6 log() zero-cell silent drop → **ADDRESSED**: stopifnot guards; PPML robustness deferred.
- M7 DDD post-cohort selection (retiming) → estimand stated explicitly in text (policy-relevant total effect on post cohort).
- M8 duckdb helpers duplicated across projects vs loader protocol → deferred: promote to shared_utils (housekeeping item).

## MINOR
- 16 items logged (sink/message stderr, on.exit at top level, unused constants, fam_classes duplication, same-date family+market collision pro-market resolution, ADMINISTRAT% over-match [FIXED], trust taxonomy comment, ntile ties, two time metrics, DDD collinear terms [FIXED], post-treatment prop snapshot caveat, F3 limits→coord_cartesian, Feb-2021 straddle, day-00 merge, family_estate n flag, POST-cohort horizon vs censor). Items marked FIXED applied in this pass; the rest are revision items.
