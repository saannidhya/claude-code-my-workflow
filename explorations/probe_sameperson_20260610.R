# Probe: C2 referee check — share of family_person events that are exact
# same-person retitling (buyer_1 full name == seller_1 full name), i.e.
# co-owner add/remove rather than intergenerational transfer.
suppressPackageStartupMessages({
  library(here); library(duckdb); library(DBI); library(glue)
})
ot_root <- normalizePath(here("data", "corelogic_extracts", "by_state", "ot"),
                         winslash = "/", mustWork = TRUE)
ot_glob <- gsub("\\\\", "/", file.path(ot_root, "state=*", "year=*", "*.parquet"))
con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")
dbExecute(con, "PRAGMA memory_limit='12GB'")
dbExecute(con, glue("PRAGMA threads={max(1L, parallel::detectCores() - 1L)}"))

q <- dbGetQuery(con, glue("
  WITH slim AS (
    SELECT
      TRY_CAST(interfamily_related_indicator AS INTEGER) AS interfam,
      upper(coalesce(buyer_1_last_name, ''))  AS b1_last,
      upper(coalesce(seller_1_last_name, '')) AS s1_last,
      upper(coalesce(buyer_1_full_name, ''))  AS b1_full,
      upper(coalesce(seller_1_full_name, '')) AS s1_full,
      upper(coalesce(buyer_2_full_name, ''))  AS b2_full,
      state,
      CAST(floor(TRY_CAST(sale_derived_date AS BIGINT) / 10000) AS INTEGER) AS sale_year
    FROM read_parquet('{gsub(\"'\", \"''\", ot_glob)}', union_by_name = true)
    WHERE residential_indicator = 'Y'
      AND TRY_CAST(sale_derived_date AS BIGINT) BETWEEN 20070101 AND 20241231
  ),
  fam AS (
    SELECT *,
      (b1_full <> '' AND b1_full = s1_full)                          AS same_person,
      (b2_full <> '' AND b2_full = s1_full)                          AS seller_is_b2,
      (b1_full LIKE '%TRUST%' OR s1_full LIKE '%TRUST%')             AS trust_kw
    FROM slim
    WHERE interfam = 1 AND b1_last <> '' AND b1_last = s1_last
  )
  SELECT
    state = 'CA' AS is_ca,
    COUNT(*) AS n_family_person_like,
    AVG(CASE WHEN trust_kw THEN 1.0 ELSE 0 END) AS trust_share,
    AVG(CASE WHEN NOT trust_kw AND (same_person OR seller_is_b2) THEN 1.0 ELSE 0 END) AS retitle_share,
    AVG(CASE WHEN NOT trust_kw AND same_person THEN 1.0 ELSE 0 END) AS exact_same_person
  FROM fam
  GROUP BY 1
"))
print(q, digits = 3)
dbDisconnect(con, shutdown = TRUE)
