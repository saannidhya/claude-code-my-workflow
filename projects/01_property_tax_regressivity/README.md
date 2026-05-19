# Project: Property Tax Assessment Regressivity

**Slug:** `property_tax_regressivity`
**Number:** 01
**Started:** 2026-05-19
**Started at SHA:** d81d9d1
**Status:** SCOPING

---

## Research Question

> Are property-tax assessments more regressive in declining neighborhoods than in growing ones, and does the pattern hold nationally beyond the documented MSA-level evidence?

(See `research_spec.md` for the full spec.)

## Key Files

- `research_spec.md` — formal spec (from `/interview-me`)
- `scripts/R/00_setup.R` — paths, sources, packages
- `scripts/R/01_clean.R` — data cleaning (sample-data dev → full)
- `scripts/R/02_analyze.R` — main regressions
- `scripts/R/03_tables.R` — manuscript tables
- `scripts/R/04_figures.R` — manuscript figures
- `manuscript/paper.tex` — manuscript draft
- `slides/seminar.tex` — seminar slides (Beamer source of truth)

## Status History

| Date | Status | Note |
|---|---|---|
| 2026-05-19 | SCOPING | Created via `/new-project property_tax_regressivity` |

## Next Steps

- [ ] Complete `research_spec.md` (run `/interview-me` if not yet done)
- [ ] Run `/lit-review` on the topic to seed `Bibliography_base.bib`
- [ ] Identify CoreLogic columns needed; sample-data exploration in `01_clean.R`
- [ ] Pre-register if hypothesis-confirmatory: `/preregister --style osf`

## Status definitions

SCOPING → EXPLORATION → ANALYSIS → WRITING → REVIEW → SUBMITTED → R&R → PUBLISHED

See `.claude/rules/project-lifecycle.md` for transition guidance.
