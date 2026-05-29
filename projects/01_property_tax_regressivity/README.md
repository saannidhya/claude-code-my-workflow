# Project: Property Tax Assessment Regressivity

**Slug:** `property_tax_regressivity`
**Number:** 01
**Started:** 2026-05-19
**Started at SHA:** d81d9d1
**Status:** EXPLORATION

---

## Research Question

> How much local-government tax revenue is misallocated by assessor information asymmetry, and which mechanism — information decay (reassessment cycle), information acquisition cost (transaction density), assessor institutional incentives, appeals technology, or transaction-frequency-driven staleness — drives the regressivity quantitatively?

(See [`research_spec.md`](research_spec.md) for the full spec.)

## Key Files

- [`research_spec.md`](research_spec.md) — formal spec (APPROVED, CoVe-verified)
- [`scripts/R/00_setup.R`](scripts/R/00_setup.R) — paths, packages (`fixest`, `modelsummary`, `duckdb`, `glue`)
- [`scripts/R/01_clean.R`](scripts/R/01_clean.R) — Berry-replication panel builder (national 2007–2010)
- [`scripts/R/02_replicate_berry.R`](scripts/R/02_replicate_berry.R) — within-jurisdiction regressivity regression
- `scripts/R/02b_decile_analysis.R` — decile-ratio analysis (TBD)
- `scripts/R/03_tables.R` — manuscript tables (template; to be filled)
- `scripts/R/04_figures.R` — manuscript figures (template; to be filled)
- [`manuscript/paper.tex`](manuscript/paper.tex) — manuscript draft
- [`slides/seminar.tex`](slides/seminar.tex) — seminar slides (Beamer source of truth)

## Decision records

- [ADR-001: National all-states scope](quality_reports/decisions/2026-05-19_national-scope.md)
- [ADR-002: Three-source identification strategy](quality_reports/decisions/2026-05-19_three-source-identification.md)
- [ADR-003: SMM estimator (first structural model)](quality_reports/decisions/2026-05-19_smm-estimator.md)
- [ADR-004: 2007–2010 sample restriction (assessment vintage)](quality_reports/decisions/2026-05-29_assessment-vintage-restriction.md)

## Replication reports

- [Berry (2021) replication](quality_reports/specs/replication_berry_2021.md) — **REPLICATED-WITH-CAVEATS** (β = −0.44 vs Berry's −0.37; difference explained by housing-bust window 2007–2010)

## Phase status

| Phase | Status | Output |
|---|---|---|
| 1. Berry replication | ✅ DONE (with caveats) | Within-jurisdiction β = −0.44, N = 11.9M, 1,773 jurisdictions |
| 1.5. Robustness sub-regressions | TODO | Year-by-year, residential-only, state-level β |
| 2. Reduced-form mechanism tests | TODO | H2–H6 tests (cycle length, density, institutions, appeals, transaction freq) |
| 3. Structural estimation (SMM) | TODO | Bayesian-assessor model in Julia |
| 4. Robustness + writing | TODO | Cook County event study, alt FE, manuscript |

## Status History

| Date | Status | Note |
|---|---|---|
| 2026-05-19 | SCOPING | Created via `/new-project property_tax_regressivity` |
| 2026-05-19 | SCOPING | Spec APPROVED after `/interview-me` + CoVe verification |
| 2026-05-29 | EXPLORATION | Phase 1 Berry replication REPLICATED-WITH-CAVEATS; advancing to Phase 1.5 + Phase 2 |

## Next Steps

- [ ] Phase 1.5 robustness: year-by-year sub-regressions, residential-only re-run, state-level β heatmap
- [ ] Phase 2: assemble reassessment-cycle data (Lincoln Institute), assessor institutional features (IAAO), ACS tract estimates (`tidycensus`)
- [ ] Phase 2: border-MSA design for H2; Bartik shift-share IV for H3
- [ ] `/lit-review` on full property-tax-regressivity literature to expand `Bibliography_base.bib`
- [ ] Contact UC CoreLogic liaison about refreshed prop extract (would unlock 2011–2024 sample window)

## Status definitions

SCOPING → **EXPLORATION** → ANALYSIS → WRITING → REVIEW → SUBMITTED → R&R → PUBLISHED

See [.claude/rules/project-lifecycle.md](../../.claude/rules/project-lifecycle.md) for transition guidance.
