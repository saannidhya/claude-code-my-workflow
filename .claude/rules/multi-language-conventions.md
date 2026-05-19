# Multi-Language Conventions

**Applies to:** any code-writing task in R, Python, Julia, LaTeX, or Markdown.

## Role allocation

| Language | Role | Why |
|---|---|---|
| **R** | Main analysis, reduced-form econometrics, tables, figures | Tidyverse + econ tools (fixest, modelsummary, did, etc.) are best-in-class for reduced-form work |
| **Python** | Scraping, API pulls (ACS, FRED, BLS), data engineering | Mature scraping ecosystem (requests, BeautifulSoup, playwright); strong API client libs |
| **Julia** | Structural modeling, optimization, simulation | Speed for solver-heavy work; JuMP, Optim, DifferentialEquations |
| **LaTeX** | Manuscripts, appendices, formal math | The default for econ journal submissions |
| **Markdown** | READMEs, project notes, internal docs | Lightweight, renders everywhere |
| **Quarto / Beamer** | Slides | Beamer is source of truth; Quarto mirrors for web |

Choose the language whose ecosystem best fits the task, not based on personal preference. If a task could go either way, R is the default.

## Cross-language data exchange

**Canonical format: Parquet.** Every language reads and writes parquet via duckdb (or arrow). CSV is a last-resort interchange format (use only for data that must be human-readable in a text editor).

| Language | Parquet read | Parquet write |
|---|---|---|
| R | `arrow::read_parquet()` or `duckdb::dbGetQuery(con, "SELECT * FROM 'path.parquet'")` | `arrow::write_parquet()` |
| Python | `duckdb.read_parquet()` or `polars.read_parquet()` | `polars.DataFrame.write_parquet()` or `pyarrow.parquet.write_table()` |
| Julia | `DuckDB.query()` against parquet file path | `DuckDB.query("COPY ... TO 'path.parquet' (FORMAT PARQUET)")` |

**No language re-derives data that another language already produced.** If `02_analyze.R` writes `transactions_clean.parquet`, then `03_model.jl` reads that parquet directly — it does not re-clean from raw.

## File organization

Within a project, organize scripts by language under `scripts/<lang>/`:

```
projects/NN_<slug>/scripts/
├── R/                  # 00_setup.R, 01_clean.R, ...
├── python/             # if used: scrapers, ACS pulls
└── julia/              # if used: modeling
```

Number scripts in run order. If R produces an input Julia consumes, name it explicitly: `R/02_analyze.R` writes `data/derived/NN/transactions_clean.parquet`, then `julia/03_solve_model.jl` reads it.

## Style guides per language

| Language | Style |
|---|---|
| R | Tidyverse style guide; lintr; `here::here()` for paths; no `setwd()`. See `r-code-conventions.md`. |
| Python | PEP 8; ruff for linting; type hints encouraged; `pathlib.Path` not strings |
| Julia | JuliaFormatter defaults; type-stable code; `joinpath()` for paths |
| LaTeX | Per `.claude/rules/single-source-of-truth.md` (Beamer first), `Preambles/header.tex` for shared macros |
| Markdown | CommonMark; no HTML where Markdown will do; line wrap at ~100 cols for readability |

## Environment reproducibility

| Language | Tool | Lockfile |
|---|---|---|
| R | `renv` | `renv.lock` (committed) |
| Python | `uv` | `uv.lock` (committed) |
| Julia | built-in Pkg | `Project.toml`, `Manifest.toml` (both committed) |

Repo root has all three. Per-project overrides allowed in `projects/NN/<lang>-env/` if a project needs a different version pin (rare).

## Cross-references

- `.claude/rules/r-code-conventions.md` — R-specific enforcement
- `.claude/rules/corelogic-data-protocol.md` — CoreLogic loader (R/Python/Julia)
- `shared_utils/{R,python,julia}/corelogic_loader.*` — cross-language entry points
