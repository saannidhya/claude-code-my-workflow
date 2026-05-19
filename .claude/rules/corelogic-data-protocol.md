# CoreLogic Data Protocol

**Applies to:** any tool call that touches CoreLogic data.

## Read-only contract

`C:\CoreLogic\` is the raw extracts root. **No tool call may write, delete, modify, rename, or chmod anything under this path.** This includes:

- `Bash` commands containing `rm`, `mv`, `cp -f`, `>`, `>>`, redirection into `C:\CoreLogic\`
- `Edit`, `Write`, `NotebookEdit` against any path under `C:\CoreLogic\`
- `git` commands that would track or modify content under `C:\CoreLogic\`
- Any conversion that would write *to* `C:\CoreLogic\` (output always goes to repo `data/`)

If a task seems to require writing under `C:\CoreLogic\`, stop and ask the user. Do not work around.

## Single loader entry point

All CoreLogic reads from project code go through one of:

- **R:** `shared_utils/R/corelogic_loader.R` — `load_corelogic_ot()`, `load_corelogic_prop()`, `load_corelogic_baseline_oh()`
- **Python:** `shared_utils/python/corelogic_loader.py` — `load_ot()`, `load_prop()`
- **Julia:** `shared_utils/julia/corelogic_loader.jl` — `load_ot()`, `load_prop()`

Project code never calls `arrow::open_dataset()`, `duckdb::dbConnect()`, `read_delim()`, `fread()`, or `pd.read_csv()` against a CoreLogic path directly. The loader is the only seam.

**Rationale:** When the data dictionary changes, when we discover a new filter rule, when we want to swap parquet ↔ raw streaming — we edit one file, not N. Every project benefits without per-project porting.

## Working format

- **Canonical store:** Apache Arrow / Parquet, partitioned by state (and year for OT)
- **Location:** `data/corelogic_extracts/by_state/{ot,prop}/state=XX[/year=YYYY]/part.parquet`
- **Conversion:** `Rscript shared_utils/R/convert_raw_to_parquet.R` (one-time per extract refresh; idempotent)
- **Cross-language access:** duckdb reads the same parquet from R, Python, and Julia — no format translation

## Sample-data dev pattern

For exploration, use:
- `data/corelogic_extracts/ot_sample_10k.parquet`
- `data/corelogic_extracts/prop_sample_10k.parquet`

Via `load_corelogic_ot(sample = TRUE)`. Promotes to full data with a one-line flip. Standard practice: develop a script against the sample, then re-run against full data for the final result.

## Prior baseline files

`data/corelogic_baseline/` holds parquet conversions of prior Stata-era cleaned + geocoded files. Access via `load_corelogic_baseline_oh(dataset, variant)`. See `data/corelogic_baseline/PROVENANCE.md` for caveats: these are NOT reproducible from this repo.

## Junk-state quarantine

The prior by-state CSV split (in `C:\CoreLogic\housing\…\by_state\`) leaked malformed-state-code rows into bogus partition files (e.g., `corelogic_ot_A.csv`, `corelogic_pc_12011.csv`). The conversion script:

1. Accepts only valid US state codes: 50 states + DC + {GU, PR, AS, VI, MP, FM, MH, PW} + APO {AA, AE, AP}
2. Quarantines other files to `data/corelogic_extracts/_quarantine/` with a row-count report
3. Never deletes raw data

User audits the quarantine later. Recoverable data can be re-incorporated.

## Cross-references

- `shared_utils/R/corelogic_loader.R` — implementation
- `data/README.md` — data inventory
- `.claude/rules/multi-language-conventions.md` — cross-language data exchange
- `.claude/rules/project-lifecycle.md` — how projects consume the loader
