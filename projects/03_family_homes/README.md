# Project: Keeping the House in the Family — Non-Market Transfers and the Supply of Homes

**Slug:** `family_homes`
**Number:** 03
**Started:** 2026-06-09
**Started at SHA:** 4702a28
**Status:** WRITING

---

## Research Question

> How large is the non-market, intra-family channel of US housing turnover; what happens to homes after they pass within families; and does the tax price of keeping a home in the family (California Proposition 19) causally affect whether inherited homes reach the market?

(See `research_spec.md` for the full spec.)

## Key Files

- `research_spec.md` — formal spec
- `scripts/R/00_setup.R` — paths, packages, duckdb helpers
- `scripts/R/01_build_panel.R` — national transfer-event panel + name-based taxonomy
- `scripts/R/02_facts.R` — RQ1 national facts (volume, composition, trends)
- `scripts/R/03_hazard.R` — RQ2 post-transfer time-to-market-sale hazard
- `scripts/R/04_prop19.R` — RQ3 Prop 19 event study + DiD
- `scripts/R/05_tables.R` — manuscript tables
- `scripts/R/06_figures.R` — manuscript figures
- `manuscript/paper.tex` — manuscript draft
- `slides/seminar.tex` — seminar slides (Beamer source of truth)

## Status History

| Date | Status | Note |
|---|---|---|
| 2026-06-09 | SCOPING | Created (manual scaffold from `projects/_template/`; `/new-project` skill unavailable in session) |
| 2026-06-09 | EXPLORATION | Feasibility probes confirm flag semantics, name taxonomy, Prop 19 spike (see `explorations/probe_*_20260609.R`) |
| 2026-06-09 | WRITING | Full pipeline run (148.7M events); first complete manuscript draft compiled (23pp); review agents dispatched |
| 2026-06-10 | WRITING | Review cycle: 3 agent reports -> panel rebuilt (retitle class + 6 data fixes), permutation inference + direct supply test added (07), all numbers recomputed, draft v2 compiled (25pp) |

## Next Steps

- [x] Feasibility probes (flag semantics, name population, clip linkage, Prop 19 visibility)
- [ ] Lit review (`/lit-review`) — intergenerational housing transfers, Prop 13/19, transfer-tax timing, misallocation
- [ ] Build national transfer-event panel with taxonomy (01)
- [ ] National facts (02), hazard (03), Prop 19 causal core (04)
- [ ] First full manuscript draft + agent reviews

## Status definitions

SCOPING → EXPLORATION → ANALYSIS → WRITING → REVIEW → SUBMITTED → R&R → PUBLISHED

See `.claude/rules/project-lifecycle.md` for transition guidance.
