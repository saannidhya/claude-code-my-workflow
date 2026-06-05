#' 05: RQ1 — within-tract vs across-tract decomposition of the price-regressivity slope
#'
#' Berry's within-jurisdiction (county-FE) elasticity is ≈ −0.42. This script
#' asks WHERE that regressivity lives: is it ACROSS neighborhoods within a
#' county (assessors misprice whole tracts — the neighborhood-mispricing story,
#' which connects to Avenancio-León & Howard's racial-assessment-gap) or WITHIN
#' neighborhoods (parcel-level valuation error)?
#'
#' Design (RQ1, see quality_reports/research_ideation_mechanisms.md):
#'   β_county = feols(log_ratio ~ log_price | county_fips)   [Berry baseline]
#'   β_tract  = feols(log_ratio ~ log_price | census_tract)  [within-tract slope]
#'   across-tract share = (β_county − β_tract) / β_county
#'   Large attenuation ⇒ regressivity is a neighborhood-mispricing phenomenon.
#'   Both models run on the IDENTICAL valid-tract sample (Gelbach/listwise
#'   discipline — see the H6 MAJOR-2 lesson).
#'
#' Robustness (vs McMillen-Singh 2023 mechanical-bias critique): a distribution-
#' based bottom/top price-decile assessment-ratio gap, computed pooled-within-
#' county vs demeaned-within-tract. Non-regression, so immune to the OLS-slope
#' mechanical bias.
#'
#' Tract geocoding: CoreLogic `census_id` (prop store) is a 10-char string
#' tract(6)+block(4) with leading zeros; ~93-97% populated in major states.
#'   census_tract (11-digit GEOID) = county_fips(5) + substr(census_id, 1, 6)
#' parcel_level_latitude is too sparse (<10% most states) to geocode from.
#'
#' Inputs:  national_panel_2007_2010.parquet (Phase 1) + census_id from the
#'          prop store (read state-by-state to dodge arrow's cross-state schema
#'          unification, mirroring 01_clean.R).
#' Output:  rq1_tract_decomposition.rds

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))
set.seed(20260605)

# ---- config ----
MIN_TRACT_COVER <- 0.70           # hard-guard: stop if < this share has a tract
DO_ACS          <- FALSE          # ACS race interaction (needs tidycensus + API key)

# ID normalizer — NEVER bare as.character() a numeric join key (H6 lesson).
norm_id <- function(x) sub("\\.0+$", "", trimws(as.character(x)))

# ---- load Phase-1 panel ----
log_msg("Loading Phase-1 panel...")
panel <- read_parquet(path(data_dir, "national_panel_2007_2010.parquet"))
log_msg("Panel rows: ", format(nrow(panel), big.mark = ","))

# ---- read census_id (clip + census_id + fips) from the prop store ----
# State-by-state column-projected read: arrow unifies schema across ALL
# partitions first, which trips on cross-state type drift (see 01_clean.R).
# census_id MUST stay character — leading zeros are significant ("0104041000").
log_msg("Reading census_id from prop store (state-by-state)...")
prop_root  <- here::here("data/corelogic_extracts/by_state/prop")
state_dirs <- fs::dir_ls(prop_root, type = "directory")
# county FIPS comes from the panel; omit fips_code here (it has cross-state
# type drift — character in some states, double in others — that breaks binding).
GEO_COLS   <- c("clip", "census_id")

geo_list <- vector("list", length(state_dirs))
for (i in seq_along(state_dirs)) {
  part <- fs::path(state_dirs[i], "part.parquet")
  if (!fs::file_exists(part)) next
  df <- tryCatch(
    arrow::read_parquet(part, col_select = dplyr::any_of(GEO_COLS)),
    error = function(e) { log_msg("  ERR ", fs::path_file(state_dirs[i]), ": ",
                                  conditionMessage(e)); NULL })
  if (is.null(df) || !all(c("clip", "census_id") %in% names(df))) next
  # Coerce to a common type BEFORE bind_rows — cross-state schema drift makes
  # clip character in some states, double in others (see 01_clean.R). census_id
  # MUST stay character to preserve leading zeros ("0104041000").
  df$clip      <- as.character(df$clip)
  df$census_id <- as.character(df$census_id)
  geo_list[[i]] <- df
  if (i %% 10L == 0L) log_msg("  ", i, "/", length(state_dirs), " states")
}
geo <- dplyr::bind_rows(geo_list)        # bind_rows: fills missing cols, drops NULLs
log_msg("Geo rows (pre-dedup): ", format(nrow(geo), big.mark = ","))

# One census_id per clip (parcel is fixed in space; take the modal/first non-NA)
geo <- geo |>
  filter(!is.na(clip), !is.na(census_id), census_id != "") |>
  mutate(clip_chr = norm_id(clip)) |>
  distinct(clip_chr, .keep_all = TRUE)
log_msg("Geo rows (one per clip): ", format(nrow(geo), big.mark = ","))

# ---- join census_id to the panel, derive the tract GEOID ----
panel <- panel |> mutate(clip_chr = norm_id(clip))
match_rate <- mean(panel$clip_chr %in% geo$clip_chr)
log_msg("Panel clips with a census_id match: ", round(100 * match_rate, 1), "%")

panel <- panel |>
  left_join(geo |> select(clip_chr, census_id), by = "clip_chr") |>
  mutate(
    county_fips = norm_id(dplyr::coalesce(.data[["fips_code_prop"]],
                                          .data[["fips_code_ot"]])),
    county_int  = suppressWarnings(as.integer(county_fips)),
    county5     = ifelse(is.na(county_int), NA_character_,
                         formatC(county_int, width = 5, flag = "0")),
    # 10-char census_id = tract(6)+block(4); tract GEOID = county(5)+tract(6)
    tract6      = ifelse(nchar(census_id) >= 10L, substr(census_id, 1, 6), NA_character_),
    census_tract = ifelse(!is.na(tract6) & !is.na(county5),
                          paste0(county5, tract6), NA_character_)
  )

cover <- mean(!is.na(panel$census_tract))
log_msg("Panel rows with a usable census_tract: ", round(100 * cover, 1), "%")

# HARD GUARD (H6 lesson): refuse to run a decomposition on a degenerate sample.
if (cover < MIN_TRACT_COVER) {
  stop("Tract coverage ", round(100 * cover, 1), "% < ", round(100 * MIN_TRACT_COVER),
       "%. census_id join or parsing likely broke — investigate before trusting β.")
}

# ---- analytic frame: identical sample for both FE models ----
d <- panel |>
  mutate(
    log_sale_price       = log(sale_amount),
    log_assessment_ratio = log(assessment_ratio)
  ) |>
  filter(
    !is.na(census_tract),
    sale_amount > 0, assessment_ratio > 0,        # positivity (MAJOR-1 lesson)
    is.finite(log_sale_price), is.finite(log_assessment_ratio),
    !is.na(county_fips), county_fips != ""
  ) |>
  group_by(census_tract) |> filter(n() >= 2L) |> ungroup()   # drop singleton tracts
log_msg("Analytic rows (valid tract, non-singleton): ", format(nrow(d), big.mark = ","))
log_msg("Distinct counties: ", format(dplyr::n_distinct(d$county_fips), big.mark = ","),
        " | distinct tracts: ", format(dplyr::n_distinct(d$census_tract), big.mark = ","))

# Cache the analytic frame so robustness/extension scripts (07, ACS) need not
# redo the state-by-state census_id merge.
write_parquet(
  d |> select(clip_chr, county_fips, census_tract, sale_amount,
              assessment_ratio, log_sale_price, log_assessment_ratio),
  path(data_dir, "rq1_analytic_frame.parquet")
)
log_msg("Cached analytic frame: rq1_analytic_frame.parquet (",
        format(nrow(d), big.mark = ","), " rows)")

# ===================================================================
# CORE DECOMPOSITION
# ===================================================================
log_msg("Fitting county-FE (Berry baseline) and tract-FE models on the same sample...")
m_county <- feols(log_assessment_ratio ~ log_sale_price | county_fips,
                  data = d, cluster = ~county_fips)
m_tract  <- feols(log_assessment_ratio ~ log_sale_price | census_tract,
                  data = d, cluster = ~county_fips)

n_c <- nobs(m_county); n_t <- nobs(m_tract)
if (n_c != n_t)
  log_msg("WARNING: county-model N (", format(n_c, big.mark = ","), ") != tract-model N (",
          format(n_t, big.mark = ","), ") from FE-singleton removal; ",
          "across-tract share is approximate.")

b_county <- unname(coef(m_county)["log_sale_price"])
b_tract  <- unname(coef(m_tract)["log_sale_price"])
across_share <- (b_county - b_tract) / b_county

# ===================================================================
# ROBUSTNESS: distribution-based decile gap (immune to OLS mechanical bias)
# bottom/top price-decile mean assessment ratio, pooled-within-county vs
# demeaned-within-tract.
# ===================================================================
decile_gap <- function(df, group_col) {
  df |>
    group_by(.data[[group_col]]) |>
    mutate(ar_dm = assessment_ratio - mean(assessment_ratio, na.rm = TRUE),
           p     = ntile(log_sale_price, 10)) |>
    ungroup() |>
    filter(p %in% c(1L, 10L)) |>
    group_by(p) |>
    summarise(mean_ar_dm = mean(ar_dm, na.rm = TRUE), .groups = "drop") |>
    tidyr::pivot_wider(names_from = p, values_from = mean_ar_dm,
                       names_prefix = "d") |>
    mutate(gap = d1 - d10) |> pull(gap)
}
gap_county <- decile_gap(d, "county_fips")
gap_tract  <- decile_gap(d, "census_tract")

# ===================================================================
# OPTIONAL: ACS tract racial-composition interaction (RQ1 extension)
# Requires tidycensus + a Census API key. Default OFF so the core runs.
# ===================================================================
if (DO_ACS) {
  log_msg("ACS: pulling tract %% non-white + median household income...")
  # library(tidycensus); census_api_key(Sys.getenv("CENSUS_API_KEY"))
  # acs <- get_acs(geography = "tract", year = 2010,
  #                variables = c(pop = "B02001_001", white = "B02001_002",
  #                              medinc = "B19013_001"),
  #                output = "wide", state = unique(substr(d$census_tract, 1, 2)))
  # acs <- acs |> mutate(pct_nonwhite = 1 - whiteE / popE) |>
  #   select(census_tract = GEOID, pct_nonwhite, medinc = medincE)
  # d_acs <- d |> inner_join(acs, by = "census_tract")
  # m_race <- feols(log_assessment_ratio ~ log_sale_price * pct_nonwhite | county_fips,
  #                 data = d_acs, cluster = ~county_fips)
  # -> tests whether the across-tract regressivity loads on tract racial composition.
  log_msg("  (ACS block is scaffolded but disabled; set DO_ACS <- TRUE to run)")
}

# ---- report ----
cat("\n\n========== RQ1: WITHIN-TRACT vs ACROSS-TRACT DECOMPOSITION ==========\n\n")
cat(sprintf("Sample: %s sales | %s counties | %s tracts\n\n",
            format(nrow(d), big.mark = ","),
            format(dplyr::n_distinct(d$county_fips), big.mark = ","),
            format(dplyr::n_distinct(d$census_tract), big.mark = ",")))
cat(sprintf("  β_county (Berry baseline, county FE) = %+.4f (SE %.4f)\n",
            b_county, unname(sqrt(diag(vcov(m_county)))["log_sale_price"])))
cat(sprintf("  β_tract  (within-tract slope, tract FE) = %+.4f (SE %.4f)\n",
            b_tract, unname(sqrt(diag(vcov(m_tract)))["log_sale_price"])))
cat(sprintf("  ACROSS-tract (neighborhood) share = (β_county − β_tract)/β_county = %.1f%%\n\n",
            100 * across_share))
cat("  Reading: high across-tract share ⇒ regressivity is neighborhood mispricing\n")
cat("           (parcels misvalued by tract); low share ⇒ within-tract parcel error.\n\n")
cat(sprintf("  Decile gap (bottom−top mean assessment ratio):\n"))
cat(sprintf("    within county = %+.4f | within tract = %+.4f  (shrinkage ⇒ across-tract)\n",
            gap_county, gap_tract))

# ---- save ----
results <- list(
  m_county = m_county, m_tract = m_tract,
  b_county = b_county, b_tract = b_tract, across_tract_share = across_share,
  gap_county = gap_county, gap_tract = gap_tract,
  n = nrow(d), n_counties = dplyr::n_distinct(d$county_fips),
  n_tracts = dplyr::n_distinct(d$census_tract),
  tract_coverage = cover, clip_match_rate = match_rate
)
saveRDS(results, path(out_dir, "rq1_tract_decomposition.rds"))
log_msg("DONE. Saved rq1_tract_decomposition.rds")
