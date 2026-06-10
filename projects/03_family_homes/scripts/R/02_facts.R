# ============================================================
# 02: RQ1 — National facts: the parallel (non-market) housing market
# Author: Saani Rawat
# Purpose: National/state volumes by taxonomy class; family:market ratios;
#          validation moments (zero-price, absentee); property correlates
#          (structure age, value tier, senior exemption) via prop join.
# Inputs:  data/derived/03_family_homes/events.parquet
#          data/corelogic_extracts/by_state/prop/ (correlates join only)
# Outputs: _outputs/tables/fact_national_by_year_class.csv
#          _outputs/tables/fact_state_class_2017_2023.csv
#          fact_headline_ratios.csv, fact_validation_moments.csv
#          fact_age_profile.csv, fact_value_quintiles.csv, fact_senior.csv
#          fact_prop_match_rate.csv
# ============================================================

source(here::here("projects/03_family_homes/scripts/R/00_setup.R"))

set.seed(20260609)

log_file <- path(logs_dir, "02_facts.log")
sink(log_file, split = TRUE)
on.exit(sink(), add = TRUE)

message("Starting 02_facts at ", Sys.time())

con <- open_corelogic_duckdb()
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
dbExecute(con, glue("PRAGMA temp_directory='{sql_quote_path(path(data_dir, 'duckdb_tmp'))}'"))

events_path <- path(data_dir, "events.parquet")
stopifnot(file_exists(events_path))
ev <- glue("read_parquet('{sql_quote_path(events_path)}')")

# Family classes: trust self-transfers are NOT counted as family transfers
fam_classes <- "('family_person','family_other','family_estate')"

# ---- 1. National volumes by year x class --------------------------------
nat <- dbGetQuery(con, glue("
  SELECT sale_year, class, COUNT(*) AS n,
         AVG(CASE WHEN amt IS NULL OR amt = 0 THEN 1.0 ELSE 0 END) AS zero_price_share,
         median(CASE WHEN amt > 0 THEN amt END) AS med_pos_price
  FROM {ev}
  WHERE sale_year BETWEEN {window_start_year} AND {full_year_end}
  GROUP BY sale_year, class ORDER BY sale_year, class
"))
assert_rows(nat, 100, "fact_national_by_year_class")
write_csv_strict(nat, path(tables_out_dir, "fact_national_by_year_class.csv"))

# ---- 2. Headline ratios -------------------------------------------------
headline <- dbGetQuery(con, glue("
  WITH t AS (
    SELECT sale_year,
      SUM(CASE WHEN class = 'family_person' THEN 1 ELSE 0 END) AS fam_conservative,
      SUM(CASE WHEN class IN {fam_classes} THEN 1 ELSE 0 END)  AS fam_broad,
      SUM(CASE WHEN class = 'family_trust' THEN 1 ELSE 0 END)  AS trust,
      SUM(CASE WHEN class = 'market_sale' THEN 1 ELSE 0 END)   AS market
    FROM {ev}
    WHERE sale_year BETWEEN {window_start_year} AND {full_year_end}
    GROUP BY sale_year
  )
  SELECT *,
         fam_conservative * 1.0 / market AS ratio_conservative,
         fam_broad * 1.0 / market        AS ratio_broad
  FROM t ORDER BY sale_year
"))
assert_rows(headline, 15, "fact_headline_ratios")
write_csv_strict(headline, path(tables_out_dir, "fact_headline_ratios.csv"))
saveRDS(headline, path(out_dir, "fact_headline_ratios.rds"))

# ---- 3. State x class (2017-2023 pooled) --------------------------------
st <- dbGetQuery(con, glue("
  SELECT state,
    SUM(CASE WHEN class IN {fam_classes} THEN 1 ELSE 0 END)  AS fam_broad,
    SUM(CASE WHEN class = 'family_trust' THEN 1 ELSE 0 END)  AS trust,
    SUM(CASE WHEN class = 'market_sale' THEN 1 ELSE 0 END)   AS market,
    COUNT(*) AS n_all
  FROM {ev}
  WHERE sale_year BETWEEN 2017 AND {full_year_end}
  GROUP BY state ORDER BY state
"))
assert_rows(st, 45, "fact_state_class")
write_csv_strict(st, path(tables_out_dir, "fact_state_class_2017_2023.csv"))

# ---- 4. Validation moments by class -------------------------------------
val <- dbGetQuery(con, glue("
  SELECT class,
         COUNT(*) AS n,
         AVG(CASE WHEN amt IS NULL OR amt = 0 THEN 1.0 ELSE 0 END) AS zero_price,
         median(CASE WHEN amt > 0 THEN amt END)                    AS med_pos_price,
         AVG(CASE WHEN dtype = 'Q' THEN 1.0 ELSE 0 END)            AS quitclaim_share,
         AVG(CASE WHEN absentee_buyer = 1 THEN 1.0 ELSE 0 END)     AS absentee_share_raw,
         AVG(CASE WHEN absentee_buyer IS NOT NULL THEN 1.0 ELSE 0 END) AS absentee_obs,
         AVG(CASE WHEN corp_buyer = 1 THEN 1.0 ELSE 0 END)         AS corp_buyer_share
  FROM {ev}
  WHERE sale_year BETWEEN {window_start_year} AND {full_year_end}
  GROUP BY class ORDER BY n DESC
"))
write_csv_strict(val, path(tables_out_dir, "fact_validation_moments.csv"))

# ---- 5. Property correlates (prop join; 2017-2023 events) ---------------
prop_glob <- sql_quote_path(prop_parquet_glob())
dbExecute(con, glue("
  CREATE OR REPLACE TEMP VIEW prop_slim AS
  -- One row per clip (deterministic), so the event join cannot fan out
  -- (r-review M4); fan-out would silently double-count correlate cells.
  SELECT clip, year_built, total_value, senior_exempt, homestead_exempt, prop_state
  FROM (
    SELECT
      TRY_CAST(clip AS BIGINT) AS clip,
      TRY_CAST(year_built AS INTEGER) AS year_built,
      TRY_CAST(calculated_total_value AS DOUBLE) AS total_value,
      CASE WHEN senior_exempt_indicator = 'Y' THEN 1 ELSE 0 END AS senior_exempt,
      CASE WHEN homestead_exempt_indicator = 'Y' THEN 1 ELSE 0 END AS homestead_exempt,
      state AS prop_state,
      ROW_NUMBER() OVER (
        PARTITION BY TRY_CAST(clip AS BIGINT)
        ORDER BY TRY_CAST(calculated_total_value AS DOUBLE) DESC NULLS LAST,
                 TRY_CAST(year_built AS INTEGER) DESC NULLS LAST, state
      ) AS rn
    FROM read_parquet('{prop_glob}', union_by_name = true)
    WHERE TRY_CAST(clip AS BIGINT) IS NOT NULL
  ) WHERE rn = 1
"))

dbExecute(con, glue("
  CREATE OR REPLACE TEMP TABLE ev_recent AS
  SELECT clip, state, sale_year, class
  FROM {ev}
  WHERE sale_year BETWEEN 2017 AND {full_year_end}
    AND class IN ('family_person','family_other','family_estate',
                  'family_trust','market_sale')
"))

n_ev_recent <- dbGetQuery(con, "SELECT COUNT(*) AS n FROM ev_recent")$n
match_rate <- dbGetQuery(con, "
  SELECT
    COUNT(*) AS n_events,
    AVG(CASE WHEN p.clip IS NOT NULL THEN 1.0 ELSE 0 END) AS match_rate
  FROM ev_recent e LEFT JOIN prop_slim p USING (clip)
")
# Join must be 1:1 on events — equality fails if prop_slim still has dup clips
stopifnot(match_rate$n_events == n_ev_recent)
message("Prop join match rate: ", round(match_rate$match_rate, 4),
        " on ", format(match_rate$n_events, big.mark = ","), " events")
write_csv_strict(match_rate, path(tables_out_dir, "fact_prop_match_rate.csv"))
# MEMORY.md lesson: assert the RATE, not just non-emptiness
if (match_rate$match_rate < 0.5) {
  stop("Prop join match rate ", match_rate$match_rate, " < 0.5 — investigate before using correlates")
}

age_profile <- dbGetQuery(con, glue("
  SELECT
    CASE
      WHEN e.sale_year - p.year_built < 10 THEN '0-9'
      WHEN e.sale_year - p.year_built < 30 THEN '10-29'
      WHEN e.sale_year - p.year_built < 50 THEN '30-49'
      WHEN e.sale_year - p.year_built < 75 THEN '50-74'
      ELSE '75+' END AS age_bin,
    SUM(CASE WHEN e.class IN {fam_classes} THEN 1 ELSE 0 END) AS fam,
    SUM(CASE WHEN e.class = 'market_sale' THEN 1 ELSE 0 END)  AS market
  FROM ev_recent e JOIN prop_slim p USING (clip)
  WHERE p.year_built BETWEEN 1800 AND e.sale_year
  GROUP BY 1 ORDER BY 1
"))
assert_rows(age_profile, 4, "fact_age_profile")
write_csv_strict(age_profile, path(tables_out_dir, "fact_age_profile.csv"))

value_q <- dbGetQuery(con, glue("
  WITH matched AS (
    SELECT e.class, p.total_value, p.prop_state,
           ntile(5) OVER (PARTITION BY p.prop_state ORDER BY p.total_value) AS vq
    FROM ev_recent e JOIN prop_slim p USING (clip)
    WHERE p.total_value > 1000
  )
  SELECT vq,
    SUM(CASE WHEN class IN {fam_classes} THEN 1 ELSE 0 END) AS fam,
    SUM(CASE WHEN class = 'market_sale' THEN 1 ELSE 0 END)  AS market
  FROM matched GROUP BY vq ORDER BY vq
"))
assert_rows(value_q, 5, "fact_value_quintiles")
write_csv_strict(value_q, path(tables_out_dir, "fact_value_quintiles.csv"))

senior <- dbGetQuery(con, glue("
  SELECT p.senior_exempt,
    SUM(CASE WHEN e.class IN {fam_classes} THEN 1 ELSE 0 END) AS fam,
    SUM(CASE WHEN e.class = 'market_sale' THEN 1 ELSE 0 END)  AS market
  FROM ev_recent e JOIN prop_slim p USING (clip)
  GROUP BY 1 ORDER BY 1
"))
write_csv_strict(senior, path(tables_out_dir, "fact_senior.csv"))

message("Finished 02_facts at ", Sys.time())
