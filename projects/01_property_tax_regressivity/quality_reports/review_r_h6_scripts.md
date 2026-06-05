# R Code Review — H6 Mediation Pipeline (scripts 01, 03, 04)

**Date:** 2026-06-05
**Reviewer:** `r-reviewer` subagent
**Triage author:** orchestrator (main session)
**Scope:** `01_clean.R`, `03_transaction_frequency.R`, `04_mechanism_h6.R` + deps

---

## Orchestrator triage (READ THIS FIRST)

The review below is thorough and mostly correct, but its **CRITICAL-1/CRITICAL-2 severity is
overstated** and I am tempering it with empirical evidence. Do not act on the raw severities;
act on this triage.

### Empirical check that the review did not have

A direct join test on the regenerated parquet (run before the review) matched
**11,934,494 of 11,934,511 panel clips (99.99986%)** using exactly the `norm_id` normalization
the review calls unsound. The clip universe here is 10-digit integers (~2–8 ×10⁹); R's
`as.character()` does **not** emit scientific notation in that range (`scipen=0` only switches
above ~15 digits). So CRITICAL-1's worst case ("back to a zero/degraded join") **did not occur**
and cannot occur for the current clip width. The in-flight `04` run will confirm `n_repeat` in
the millions and `stop()` if it doesn't.

### Re-rated findings

| Review ID | Review severity | My rating | Why |
|---|---|---|---|
| CRITICAL-1 (`norm_id` bare `as.character`) | CRITICAL | **Latent / hardening** | 99.9999% match empirically; no sci-notation at 10-digit clip width. Real as defensive coding — pin ID type at source — but **not blocking**. |
| CRITICAL-2 (`sale_chr` double round-trip) | CRITICAL | **Latent / hardening** | 8-digit dates never hit sci-notation; same defensive fix folds in. |
| CRITICAL-3 (guard is absolute count, late) | CRITICAL | **MAJOR — do it** | Correct: a 99%-degraded join clears a 1000-row guard. Assert match **rate** at the join. Cheap, high value. |
| CRITICAL-4 / MAJOR-7 (contaminated `secondary_share` saved) | CRITICAL | **MAJOR — do it** | Correct and exactly how the first fabrication entered. Don't save a "share mediated" off forward-looking `n_txn`. |
| MAJOR-2 (Gelbach sample identity) | MAJOR | **Largely mitigated; assert it** | `repeat_panel`/`full_freq` already pre-filter on the mediator's non-NA, so base and mediated share a sample. Add `stopifnot(nobs(base)==nobs(mediated))` to *prove* it; unlikely to move the number. |
| MAJOR-3 (year-truncation staleness) | MAJOR | **MAJOR — affects the number** | Genuine measurement-validity issue. `floor(YYYYMMDD/10000)` quantizes staleness to ±1yr and forces same-year repeats to 0. Move to day-level gap before trusting the primary share. |
| MAJOR-1 (unguarded `log()` of non-positive) | MAJOR | **MAJOR — assert** | `sale_amount`/`assessment_ratio` filtered upstream but not re-asserted; `-Inf` would silently poison `feols`. Add positivity filter + finite assertion. |
| MAJOR-5/6 (clip type at source; `bind_rows`) | MAJOR | **Hardening — do with CRITICAL-1 fix** | Pinning `clip` to `integer64`/character in `01`/loader dissolves the whole bug class. `bind_rows` over `rbind` is correct. |
| MINOR-4 (loader-protocol violation) | MINOR | **MAJOR governance** | `01_clean.R` reads prop via `arrow::read_parquet` directly — a documented `corelogic-data-protocol.md` violation. Route through `load_corelogic_prop()`. |
| MINOR-1,2,3,5,6,7,8,9 | MINOR | **MINOR — polish** | Fine to batch later. |

### What this means for the in-flight run

The number the running `04` produces is a **valid join** but rests on the **year-truncated
staleness measure (MAJOR-3)** and saves a **contaminated secondary share (CRITICAL-4)**. So treat
its primary share as **provisional**, confirm the join works end-to-end, then apply MAJOR-3 +
CRITICAL-4 + CRITICAL-3 (rate guard) + MAJOR-1 (positivity) and **re-run once** for the number
that goes in the spec and the correction commit. CRITICAL-1/2 ID-pinning ride along as hardening.

---

## Full review (verbatim from the r-reviewer subagent)

**Verdict:** The advertised fix is NOT sound (see triage — I disagree on severity). 4 CRITICAL, 7 MAJOR, 9 MINOR.

### CRITICAL

**CRITICAL-1** — `norm_id()` (`04:52`) uses bare `as.character()` on a numeric double; `sub("\\.0+$","")` does not fix scientific notation that large doubles can emit. The author's own `_diag_h6_join.R:9` used `format(clip, scientific=FALSE)` and labeled bare `as.character` as the OLD bug path. Fix: never round-trip an ID through double; coerce to `bit64::integer64` or notation-stable string; pin at source in `01_clean.R`/loader. Add a positive control asserting match rate > 0 before the guard.

**CRITICAL-2** — `sale_chr` built from a double via `norm_id` (`04:57,61,68-69,77`); 8-digit dates work today but are the same latent landmine, and the lag `sale_raw = TRY_CAST(... AS BIGINT)` can drop malformed dates asymmetrically vs the panel. Fix: `format(as.integer64(x), scientific=FALSE)` on both sides; log date-key population symmetry.

**CRITICAL-3** — hard guard `n_repeat < 1000` (`04:101-116`) runs after derivation/filtering and is an absolute count. A 1%-matched (99%-broken) join clears it. Fix: assert match **rate** right after the join (`mean(!is.na(prior_sale_raw)) > 0.20`), keep `n_repeat` guard but raise to a fraction of the expected ~9.95M, and guard the frequency join too.

**CRITICAL-4** — secondary `n_txn` join (`04:66-67,144-148`) has no guard; if it zeroes out, `full_freq` is empty and `feols` runs degenerate, yet `secondary_share` is printed and saved (`04:201`). This is how the first fabrication happened. Fix: guard every subsample feeding `feols`.

### MAJOR

**MAJOR-1** — unguarded `log()` of `sale_amount`/`assessment_ratio`/`n_txn_total` (`04:84-86`); upstream filters not re-asserted in `04`. Add positivity filter + finite assertion before logging.

**MAJOR-2** — `feols` listwise-deletes; Gelbach `c-c'` requires identical base/mediated sample. Freeze one `drop_na` frame per decomposition and `stopifnot(nobs(base)==nobs(mediated))`. (Triage: pre-filters largely handle this already.)

**MAJOR-3** — `years_since_prior_sale = floor(YYYYMMDD/10000)` difference (`04:77-79`) extracts year only: ±1yr quantization, same-year repeats → 0 kept by the `>=0` filter. The mediator doesn't measure what H6 claims. Fix: day-level gap via `as.Date(..., "%Y%m%d")`, `/365.25`.

**MAJOR-4** — `as.numeric(sale_chr)` (`04:77-78`) re-introduces char→double; prefer `as.integer(substr(sale_chr,1,4))`.

**MAJOR-5** — `clip` join type never pinned in `01_clean.R` (`99-104,129-130`); per-state schema drift can coerce inconsistently. Coerce `clip` to `integer64`/character at read.

**MAJOR-6** — `do.call(rbind, prop_list)` (`01:91`) breaks on unequal columns / is slow; use `dplyr::bind_rows()`.

**MAJOR-7** — `n_txn_total` includes post-focal sales (forward-looking); `secondary_share` computed/saved as if comparable. Restrict to backward-looking count or don't save the share.

### MINOR
1. `log_msg`=`cat()` everywhere violates console-output hygiene; prefer `message()`, one per section.
2. No `set.seed(YYYYMMDD)` — add for convention/future robustness passes.
3. Integer-literal discipline (`0L`, count literals).
4. `here()`/direct `arrow::read_parquet` calls outside `00_setup.R`; `01_clean.R` bypasses the loader seam (protocol violation).
5. Derived-file path string-literals duplicated across `03`/`04`; define once in `00_setup.R`.
6. `gsub("\\\\","/")` repeated 4× in `03`; wrap in a helper.
7. Magic numbers (`18000101`, `20251231`, `150`) → named constants; doc says "1900" but code allows 1800.
8. Three different "extract year from YYYYMMDD" implementations across the codebase; consolidate.
9. `norm_id`/`get_b`/`get_se` undocumented; results list should carry `nobs` + sample-equality flag.

### Cross-cutting priority
1. Pin ID type at source (dissolves CRITICAL-1/2, MAJOR-4/5).
2. Guard at the join, by rate, every subsample.
3. Freeze one estimation frame per decomposition.
4. Don't save `secondary_share` without a `descriptive_only` label.
5. Re-run only after a positive-control match-rate check.
