# CoreLogic Research Codebase

> Multi-project research repository centered on CoreLogic property + transaction data.
> Maintained by [Saani Rawat](https://www.marquette.edu/business/faculty-staff/saani-rawat.php), Assistant Professor of Real Estate at Marquette University.

## What's here

End-to-end research workflow for papers using the CoreLogic University-of-Cincinnati extract (transactions + property characteristics). Each paper lives under `projects/NN_<slug>/` with its own scripts, manuscript, and slides. Shared infrastructure (data loaders, LaTeX preamble, bibliography, Quarto theme) lives at the root.

## Languages

- **R** — main analysis, reduced-form econometrics
- **Python** — data scraping, ACS pulls, geocoding pipelines
- **Julia** — structural modeling, optimization
- **LaTeX** — manuscripts (journal-agnostic article + natbib)
- **Quarto / Beamer** — seminars + conference slides

## Current projects

_None yet. Start with `/new-project <slug>` from within Claude Code._

## Workflow

This repo uses the [Claude Code academic workflow](https://github.com/pedrohcgs/claude-code-my-workflow) (v1.8.0 fork), customized for CoreLogic research. Key commands:

- `/new-project <slug>` — scaffold a new project
- `/interview-me` — formalize a research idea
- `/lit-review <topic>` — literature search + synthesis
- `/data-analysis` — guided R analysis
- `/review-paper --peer <journal>` — simulated peer-review
- `/audit-reproducibility` — paper ↔ code consistency check

See [CLAUDE.md](CLAUDE.md) for the full command list and folder structure.

## Data

CoreLogic raw extracts live at `C:\CoreLogic\` (read-only). The repo's `data/` directory is gitignored and holds working data: parquet conversions, samples, baseline-wrapped prior outputs, external sources (ACS, weather, Zillow, etc.), and per-project derived datasets.

See [data/README.md](data/README.md) for the data inventory and [.claude/rules/corelogic-data-protocol.md](.claude/rules/corelogic-data-protocol.md) for the read-only contract.

## Reproducibility

- **R:** `renv` (lockfile at `renv.lock`)
- **Python:** `uv` (lockfile at `uv.lock`)
- **Julia:** `Pkg.instantiate()` from `Project.toml`

To replicate a paper: navigate to `projects/NN_<slug>/`, restore the environment, then run scripts in numbered order (`00_setup.R` → `01_clean.R` → …).

## License

- Code: MIT (see [LICENSE](LICENSE))
- CoreLogic data: not redistributed; licensed via University of Cincinnati academic agreement
- Workflow infrastructure: forked from pedrohcgs/claude-code-my-workflow under its original license

## Acknowledgments

Workflow infrastructure adapted from [Pedro H. C. Sant'Anna's academic Claude Code workflow](https://github.com/pedrohcgs/claude-code-my-workflow). All research errors are my own.
