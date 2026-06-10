# Probe 2: national interfamily-transfer coverage + CA Prop 19 spike test
# Sandbox exploration — 2026-06-09
# Uses the duckdb-over-parquet pattern established in project 02.

suppressPackageStartupMessages({
  library(here)
  library(duckdb)
  library(DBI)
  library(glue)
})

ot_root <- normalizePath(here("data", "corelogic_extracts", "by_state", "ot"),
                         winslash = "/", mustWork = TRUE)
ot_glob <- gsub("\\\\", "/", file.path(ot_root, "state=*", "year=*", "*.parquet"))

con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")
dbExecute(con, "PRAGMA memory_limit='12GB'")
dbExecute(con, glue("PRAGMA threads={max(1L, parallel::detectCores() - 1L)}"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW ot AS
  SELECT
    TRY_CAST(sale_derived_date AS BIGINT) AS sale_raw,
    CAST(floor(TRY_CAST(sale_derived_date AS BIGINT) / 10000) AS INTEGER) AS sale_year,
    CAST(floor(TRY_CAST(sale_derived_date AS BIGINT) / 100) % 100 AS INTEGER) AS sale_month,
    TRY_CAST(interfamily_related_indicator AS INTEGER) AS interfam,
    primary_category_code AS pcat,
    deed_category_type_code AS dtype,
    TRY_CAST(sale_amount AS DOUBLE) AS amt,
    residential_indicator AS resid,
    TRY_CAST(resale_indicator AS INTEGER) AS resale,
    state
  FROM read_parquet('{gsub(\"'\", \"''\", ot_glob)}', union_by_name = true)
"))

cat("=== 1. National rows + interfamily share by sale_year, 1985-2024 ===\n")
q1 <- dbGetQuery(con, "
  SELECT sale_year,
         COUNT(*) AS n,
         AVG(CASE WHEN interfam IS NULL THEN 1.0 ELSE 0 END) AS fam_na_share,
         AVG(CASE WHEN interfam = 1 THEN 1.0 ELSE 0 END) AS fam_share,
         AVG(CASE WHEN pcat = 'A' THEN 1.0 ELSE 0 END) AS pcatA_share,
         AVG(CASE WHEN pcat = 'B' THEN 1.0 ELSE 0 END) AS pcatB_share
  FROM ot
  WHERE sale_year BETWEEN 1985 AND 2024
  GROUP BY sale_year ORDER BY sale_year
")
print(q1, row.names = FALSE, digits = 3)

cat("\n=== 2. Semantics: by primary_category_code (2015-2024) ===\n")
q2 <- dbGetQuery(con, "
  SELECT pcat,
         COUNT(*) AS n,
         AVG(CASE WHEN interfam = 1 THEN 1.0 ELSE 0 END) AS fam_share,
         AVG(CASE WHEN amt IS NULL OR amt = 0 THEN 1.0 ELSE 0 END) AS zero_amt_share,
         median(CASE WHEN amt > 0 THEN amt END) AS med_pos_amt,
         AVG(CASE WHEN resid = 'Y' THEN 1.0 ELSE 0 END) AS resid_share
  FROM ot
  WHERE sale_year BETWEEN 2015 AND 2024
  GROUP BY pcat ORDER BY n DESC
")
print(q2, row.names = FALSE, digits = 3)

cat("\n=== 3. Semantics: by deed_category_type_code (2015-2024, top 12) ===\n")
q3 <- dbGetQuery(con, "
  SELECT dtype,
         COUNT(*) AS n,
         AVG(CASE WHEN interfam = 1 THEN 1.0 ELSE 0 END) AS fam_share,
         AVG(CASE WHEN amt IS NULL OR amt = 0 THEN 1.0 ELSE 0 END) AS zero_amt_share,
         median(CASE WHEN amt > 0 THEN amt END) AS med_pos_amt
  FROM ot
  WHERE sale_year BETWEEN 2015 AND 2024
  GROUP BY dtype ORDER BY n DESC LIMIT 12
")
print(q3, row.names = FALSE, digits = 3)

cat("\n=== 4. CA monthly interfamily counts 2019-2022 (Prop 19 spike test) ===\n")
q4 <- dbGetQuery(con, "
  SELECT sale_year, sale_month,
         COUNT(*) AS n_all,
         SUM(CASE WHEN interfam = 1 THEN 1 ELSE 0 END) AS n_fam
  FROM ot
  WHERE state = 'CA' AND sale_year BETWEEN 2019 AND 2022
  GROUP BY sale_year, sale_month ORDER BY sale_year, sale_month
")
print(q4, row.names = FALSE)

dbDisconnect(con, shutdown = TRUE)
cat("\nDone.\n")
