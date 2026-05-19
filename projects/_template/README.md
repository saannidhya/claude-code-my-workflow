# Project: {{PROJECT_NAME}}

**Slug:** `{{PROJECT_SLUG}}`
**Number:** {{PROJECT_NUMBER}}
**Started:** {{START_DATE}}
**Started at SHA:** {{START_SHA}}
**Status:** SCOPING

---

## Research Question

> {{ONE_SENTENCE_RQ}}

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
| {{START_DATE}} | SCOPING | Created via `/new-project {{PROJECT_SLUG}}` |

## Next Steps

- [ ] Complete `research_spec.md` (run `/interview-me` if not yet done)
- [ ] Run `/lit-review` on the topic to seed `Bibliography_base.bib`
- [ ] Identify CoreLogic columns needed; sample-data exploration in `01_clean.R`
- [ ] Pre-register if hypothesis-confirmatory: `/preregister --style osf`

## Status definitions

SCOPING → EXPLORATION → ANALYSIS → WRITING → REVIEW → SUBMITTED → R&R → PUBLISHED

See `.claude/rules/project-lifecycle.md` for transition guidance.
