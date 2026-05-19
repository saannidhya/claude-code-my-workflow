# data/

**All contents of this directory are gitignored.** Only the structure (via
`.gitkeep` files) and this README ship in the repo.

## Subdirectories

### `corelogic_extracts/`
Parquet conversions of `C:\CoreLogic\` raw extracts.
- `by_state/ot/state=XX/year=YYYY/part.parquet` — Owner Transfer, partitioned
- `by_state/prop/state=XX/part.parquet` — Property Characteristics, partitioned
- `ot_sample_10k.parquet`, `prop_sample_10k.parquet` — random samples for fast dev
- `data_dictionary.csv` — parsed dd.txt
- `_quarantine/` — files with malformed state codes (from prior by-state CSV split)
- `_logs/` — conversion logs

Populated by: `Rscript shared_utils/R/convert_raw_to_parquet.R` (one-time per extract refresh).

### `corelogic_baseline/`
Wrapped versions of prior Ohio cleaned + geocoded files (originally in
`C:\CoreLogic\housing\*.csv`). See `PROVENANCE.md` for what was done before
this repo existed.

### `external/`
Non-CoreLogic data: ACS, Zillow, weather, FEMA, etc. Each source gets its own
subdirectory with a README documenting source URL, retrieval date, version.

### `derived/`
Per-project cleaned data, organized by project: `derived/01_<slug>/`,
`derived/02_<slug>/`. Each project's `01_clean.R` writes here.

## Why gitignored

- CoreLogic data is licensed; cannot be redistributed
- Parquet files are large (GBs)
- All contents are regenerable from raw extracts + scripts
