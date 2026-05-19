# CoreLogic Baseline Inputs (Ohio)

**Last updated:** 2026-05-19
**Source files (read-only):** `C:\CoreLogic\housing\corelogic_*.csv`
**Wrapped by:** `shared_utils/R/wrap_baseline.R`
**Wrapped on:** {{FILL DATE OF WRAP RUN}}

---

## Origin

These files predate this repo. They were produced by prior CoreLogic work
(Stata-era) using the University of Cincinnati academic extract.

## Source-to-target mapping

| Source CSV | Target parquet | Notes |
|---|---|---|
| `corelogic_ot_oh_2021_2024_cleaned.csv` | `ot_oh_2021_2024_cleaned.parquet` | OT cleaning applied (filter rules unknown — Stata code not in repo) |
| `corelogic_ownertransfer_geocoded_oh_0724.csv` | `ot_oh_geocoded_2007_2024.parquet` | OT 2007-2024 with lat/lon |
| `corelogic_ownertransfer_geocoded_oh_1620.csv` | `ot_oh_geocoded_2016_2020.parquet` | Subset 2016-2020 |
| `corelogic_ownertransfer_geocoded_oh_2124.csv` | `ot_oh_geocoded_2021_2024.parquet` | Subset 2021-2024 |
| `corelogic_property_full_geocoded.csv` | `prop_oh_full_geocoded.parquet` | NATIONAL property file, geocoded (namespaced under `prop_oh_*` for loader-contract convenience) |
| `corelogic_property_full_geocoded_oh.csv` | `prop_oh_geocoded.parquet` | OH-only property file, geocoded |
| `corelogic_property_geocoded_with_cousub_oh.csv` | `prop_oh_geocoded_with_cousub.parquet` | + County Subdivision (cousub) spatial join |
| `corelogic_property_geocoded_with_cousub_place_oh.csv` | `prop_oh_geocoded_with_cousub_place.parquet` | + Place (incorporated place) spatial join |

## Pipeline that produced these (best understanding)

This is what we believe was done. Saani Rawat should fill in details where
"???" appears; honest gaps stay as "???".

1. **OT extraction:** Filter raw Owner Transfer to Ohio (FIPS state code = "39")
2. **OT cleaning (2021-2024 only):** ??? (which filters? arms-length? min price? what columns dropped?)
3. **OT geocoding:** ??? (which geocoder — Census? Nominatim? Google API? cached results?)
4. **Property extraction:** Filter raw Property Characteristics to Ohio
5. **Property geocoding:** ??? (same questions as OT)
6. **Spatial joins:**
   - `with_cousub`: spatial join to TIGER/Line County Subdivision shapefile (year ???)
   - `with_cousub_place`: above + spatial join to TIGER/Line Place shapefile (year ???)

## Caveats

- **Not reproducible from this repo.** The Stata code that produced these is not under version control here. For replication, ask Saani.
- **Filter rules unknown.** The "cleaned" file has had unknown filters applied. Don't assume it's a superset of raw.
- **Geocoder unknown.** Match accuracy / cache age unknown. For new geocoding needs, write fresh code via `shared_utils/R/geocoding.R` (placeholder for now).
- **Shapefile vintages unknown.** Spatial joins may use stale boundaries. Check tigris year if joining to anything new.

## Recommended use

OK Use for:
- Quick replication of prior work
- Sanity checking new pipelines against a known baseline
- Exploratory analysis where rebuilding from raw is overkill

NOT for:
- Final publication results without auditing the cleaning rules
- Combining with newly-cleaned data in the same analysis (filters may differ)
- Geocoding-sensitive analyses without confirming geocoder + shapefile vintage

## Refresh policy

If the underlying CoreLogic extract is refreshed, prior baselines do NOT
auto-update. Re-derive from raw via the `shared_utils/R/` pipeline, or
re-run the Stata code (if available) and re-wrap.
