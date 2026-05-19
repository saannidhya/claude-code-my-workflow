# Research Spec: {{PROJECT_NAME}}

**Slug:** `{{PROJECT_SLUG}}`
**Date drafted:** {{DATE}}
**Status:** DRAFT | APPROVED

---

## Research Question

> {{ONE_SENTENCE_RQ}}

Why this matters: {{2-3 sentences on the gap or policy relevance}}

## Hypotheses

| # | Hypothesis | Direction | Falsifiable? |
|---|------------|-----------|--------------|
| H1 | {{Statement}} | + / − / null | yes / no |
| H2 | | | |

## Identification Strategy

**Setting:** {{What variation are we exploiting?}}
**Method:** {{OLS / DiD / IV / RDD / event study / structural / ...}}
**Identifying assumption:** {{Spell out the parallel-trends / exogeneity / exclusion-restriction etc.}}
**Threats to identification:** {{2-3 most plausible alternative explanations}}

## Data Requirements

| Source | Variables | Coverage (geo / time) | Notes |
|---|---|---|---|
| CoreLogic OT | {{e.g., sale price, date, parcel ID, ...}} | {{e.g., OH 2010-2024}} | |
| CoreLogic Prop | {{...}} | | |
| External (ACS / Zillow / ...) | | | |

## Empirical Strategy

1. Sample construction: {{rules for inclusion/exclusion}}
2. Treatment definition: {{what counts as treated}}
3. Primary specification: {{equation in text or LaTeX}}
4. Standard errors: {{cluster level}}
5. Robustness: {{2-3 most important checks}}

## Outputs Plan

- Tables: {{T1 = summary stats, T2 = main results, T3 = heterogeneity, T4 = robustness}}
- Figures: {{F1 = sample map, F2 = event-study, F3 = treatment effect heterogeneity}}

## Timeline

| Milestone | Target date |
|---|---|
| EXPLORATION → ANALYSIS | |
| ANALYSIS → WRITING | |
| WRITING → REVIEW | |
| Submit to {{journal}} | |

## Open Questions

- {{Anything that needs follow-up before this becomes ANALYSIS-ready}}
