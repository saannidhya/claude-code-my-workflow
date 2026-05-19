# Data Provenance: {{DATASET_NAME}}

**Last updated:** {{DATE}}
**Source:** {{FILE_PATH_OR_URL}}
**Maintainer:** {{NAME}}

---

## Origin

{{Where did this data come from? Original source URL, vendor, agreement
license, retrieval date.}}

## Pipeline

{{How was it produced from raw? List the steps. If the pipeline is in this
repo, link to the scripts; if external (e.g., prior Stata code), be honest
that it's not reproducible from this repo.}}

| Step | What | Where (code) | Run by | Date |
|---|---|---|---|---|
| 1 | Read raw | | | |
| 2 | Clean | | | |
| 3 | Geocode | | | |

## Schema

| Column | Type | Description | Notes |
|---|---|---|---|
| `<name>` | `<type>` | | |

## Known issues / caveats

- {{Anything that future users need to know — encoding quirks, missing
  geographies, suspicious value ranges, etc.}}

## Recommended use

- {{What this data is appropriate for}}
- {{What it is NOT appropriate for}}

## Refresh policy

{{How often does this need to be re-derived? On what trigger?}}
