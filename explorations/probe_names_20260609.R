# Probe 3: name-based taxonomy feasibility + data truncation
# Sandbox exploration — 2026-06-09
# Q1: Are buyer/seller last names populated? Same-surname share among interfamily?
# Q2: What share of "interfamily" is trust self-transfers?
# Q3: Where does 2024 truncate? Is 2006 partial?
# Q4: Can clip link repeat events (post-transfer resale hazard feasible)?

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
    TRY_CAST(clip AS BIGINT) AS clip,
    CAST(floor(TRY_CAST(sale_derived_date AS BIGINT) / 10000) AS INTEGER) AS sale_year,
    TRY_CAST(sale_derived_date AS BIGINT) AS sale_raw,
    TRY_CAST(interfamily_related_indicator AS INTEGER) AS interfam,
    primary_category_code AS pcat,
    deed_category_type_code AS dtype,
    TRY_CAST(sale_amount AS DOUBLE) AS amt,
    upper(coalesce(buyer_1_last_name, '')) AS b1_last,
    upper(coalesce(seller_1_last_name, '')) AS s1_last,
    upper(coalesce(buyer_1_full_name, '')) AS b1_full,
    upper(coalesce(seller_1_full_name, '')) AS s1_full,
    buyer_1_corporate_indicator AS b1_corp,
    residential_indicator AS resid,
    state
  FROM read_parquet('{gsub(\"'\", \"''\", ot_glob)}', union_by_name = true)
"))

cat("=== 1. Name population + surname match among interfamily, 2010-2024 ===\n")
q1 <- dbGetQuery(con, "
  SELECT
    CASE WHEN interfam = 1 THEN 'fam' ELSE 'nonfam' END AS grp,
    COUNT(*) AS n,
    AVG(CASE WHEN b1_last <> '' THEN 1.0 ELSE 0 END) AS b1_last_pop,
    AVG(CASE WHEN s1_last <> '' THEN 1.0 ELSE 0 END) AS s1_last_pop,
    AVG(CASE WHEN b1_last <> '' AND b1_last = s1_last THEN 1.0 ELSE 0 END) AS same_surname,
    AVG(CASE WHEN b1_full LIKE '%TRUST%' THEN 1.0 ELSE 0 END) AS buyer_trust,
    AVG(CASE WHEN s1_full LIKE '%TRUST%' THEN 1.0 ELSE 0 END) AS seller_trust,
    AVG(CASE WHEN b1_full LIKE '%ESTATE%' OR s1_full LIKE '%ESTATE%' THEN 1.0 ELSE 0 END) AS estate_any
  FROM ot
  WHERE sale_year BETWEEN 2010 AND 2024
  GROUP BY 1
")
print(q1, row.names = FALSE, digits = 3)

cat("\n=== 2. Interfamily decomposition (2010-2024): trust vs same-surname vs other ===\n")
q2 <- dbGetQuery(con, "
  SELECT
    CASE
      WHEN b1_full LIKE '%TRUST%' OR s1_full LIKE '%TRUST%' THEN 'trust_involved'
      WHEN b1_last <> '' AND b1_last = s1_last THEN 'same_surname'
      WHEN b1_full LIKE '%ESTATE%' OR s1_full LIKE '%ESTATE%' THEN 'estate'
      ELSE 'other'
    END AS subtype,
    COUNT(*) AS n,
    AVG(CASE WHEN amt IS NULL OR amt = 0 THEN 1.0 ELSE 0 END) AS zero_amt,
    AVG(CASE WHEN state = 'CA' THEN 1.0 ELSE 0 END) AS ca_share
  FROM ot
  WHERE interfam = 1 AND sale_year BETWEEN 2010 AND 2024
  GROUP BY 1 ORDER BY n DESC
")
print(q2, row.names = FALSE, digits = 3)

cat("\n=== 3. Truncation: monthly rows 2024 + 2006 ===\n")
q3 <- dbGetQuery(con, "
  SELECT sale_year, CAST(floor(sale_raw / 100) % 100 AS INTEGER) AS m, COUNT(*) AS n
  FROM ot WHERE sale_year IN (2006, 2024)
  GROUP BY 1, 2 ORDER BY 1, 2
")
print(q3, row.names = FALSE)

cat("\n=== 4. Clip linkage: records per clip (2007-2024) ===\n")
q4 <- dbGetQuery(con, "
  WITH per_clip AS (
    SELECT clip, COUNT(*) AS k
    FROM ot
    WHERE clip IS NOT NULL AND sale_year BETWEEN 2007 AND 2024
    GROUP BY clip
  )
  SELECT
    COUNT(*) AS n_clips,
    AVG(k) AS mean_records,
    SUM(CASE WHEN k >= 2 THEN 1 ELSE 0 END) AS clips_2plus
  FROM per_clip
")
print(q4, row.names = FALSE, digits = 4)

cat("\n=== 5. National annual interfamily counts, RESIDENTIAL only ===\n")
q5 <- dbGetQuery(con, "
  SELECT sale_year,
         SUM(CASE WHEN interfam = 1 THEN 1 ELSE 0 END) AS n_fam,
         SUM(CASE WHEN pcat = 'A' THEN 1 ELSE 0 END) AS n_arms,
         COUNT(*) AS n_all
  FROM ot
  WHERE resid = 'Y' AND sale_year BETWEEN 2007 AND 2024
  GROUP BY sale_year ORDER BY sale_year
")
print(q5, row.names = FALSE)

dbDisconnect(con, shutdown = TRUE)
cat("\nDone.\n")
