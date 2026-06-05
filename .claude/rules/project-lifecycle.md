# Project Lifecycle

**Applies to:** any work under `projects/NN_<slug>/`.

## Naming

- Format: `projects/NN_<short_slug>/`
- `NN`: zero-padded two-digit number, auto-assigned by `/new-project` (scans existing folders, picks next)
- `<short_slug>`: snake_case, descriptive, ≤ 30 chars (e.g., `property_tax_capitalization`, `climate_risk_pricing`, `ibuyer_pricing`)
- Once assigned, the number never changes. Slugs can be renamed via a git mv + CLAUDE.md update.

## Scaffold

Always via `/new-project <slug>`. Manual creation is discouraged — the skill enforces the conventions in `projects/_template/` and registers the project in `CLAUDE.md`.

## Status states

Each project's `README.md` has a status field, one of:

| State | Meaning | Typical artifacts |
|---|---|---|
| `SCOPING` | RQ being refined; no analysis yet | `research_spec.md` drafted |
| `EXPLORATION` | Sample-data analysis, sandbox plots | `_outputs/` has WIP `.rds` |
| `ANALYSIS` | Main regressions, full-data runs | `03_tables.R` produces stable tables |
| `WRITING` | Manuscript draft underway | `paper.tex` compiles; sections drafted |
| `REVIEW` | Pre-submission review (peer / mentor) | `/review-paper --peer` reports exist |
| `SUBMITTED` | Out for review at journal | Journal name + date in README |
| `R&R` | Revise-and-resubmit | Referee reports + `/respond-to-referees` outputs |
| `PUBLISHED` | Done | DOI in README, replication package tagged |

Transitions are manual — update the README, commit the change.

## Folder structure (enforced by template)

```
projects/NN_<slug>/
├── README.md                  Status, RQ, key files, next steps
├── research_spec.md           From /interview-me
├── scripts/
│   ├── R/                     00_setup.R + numbered analysis scripts
│   │   └── _outputs/          gitignored intermediates
│   ├── python/                scrapers, ACS pulls
│   └── julia/                 modeling
├── manuscript/
│   ├── paper.tex              Generic article + natbib
│   ├── appendix.tex
│   ├── tables/                Auto-generated from R
│   └── figures/               Auto-generated from R
├── slides/
│   ├── seminar.tex            Beamer source of truth
│   ├── seminar.qmd            Quarto mirror
│   └── figures/
└── quality_reports/
    ├── specs/, plans/, session_logs/, decisions/, checkpoints/
```

## Code conventions inside a project

- **R:** Every script begins with `source(here::here("projects/NN_<slug>/scripts/R/00_setup.R"))`. The setup file is the only file that touches paths.
- **No hardcoded paths** anywhere — `here::here()` always.
- **No `setwd()`** ever. See `r-code-conventions.md`.
- **Cross-language data exchange via parquet** — see `multi-language-conventions.md`.

## Project-aware skills

These skills accept a `--project NN` flag (or auto-detect from cwd):

- `/data-analysis` — default outputs to `projects/NN/scripts/R/`
- `/lit-review`, `/interview-me`, `/research-ideation`, `/preregister`
- `/review-paper`, `/review-r`, `/verify-claims`, `/seven-pass-review`, `/respond-to-referees`
- `/audit-reproducibility` — walks `projects/NN/scripts/R/_outputs/`
- `/compile-latex`
- `/commit` — detects which project a commit touches; includes name in PR title

## Per-project quality reports

Project-specific work logs/specs/plans go in `projects/NN/quality_reports/` (not root). Root `quality_reports/` is for repo-level work (e.g., this workflow adaptation spec/plan).

## Cross-references

- `.claude/skills/new-project/SKILL.md` — scaffold implementation
- `templates/project-readme.md`, `templates/project-research-spec.md`
- `.claude/rules/corelogic-data-protocol.md` — data access from projects
- `.claude/rules/r-code-conventions.md` — R style enforcement
