#' 09: Shored-up division-bias IV.
#'
#' Improves on 08 (the first cut) per the option-(B) plan:
#'   - DEFLATES the repeat-sale instruments by the FHFA state-year HPI, so a
#'     prior/subsequent price is expressed in focal-year value terms (removes
#'     appreciation between sales; only the cross-sectional value signal remains).
#'   - DROPS the hedonic instrument as a headline IV (its exclusion fails: the
#'     assessor uses the same characteristics). Replaces it with the parcel's
#'     SUBSEQUENT arms-length sale price — a second independent MARKET draw of
#'     true value that does NOT share information with the assessor.
#'   - Over-identified IV (prior + subsequent) -> Hansen J between two
#'     valid-class market instruments (J should NOT reject if both are valid).
#'   - Reports the level-on-level gamma (log assessed on log price; regressivity
#'     = gamma < 1) alongside the ratio slope.
#'
#' Decisive question (unchanged): does beta_tract < beta_county SURVIVE under IV?
#'
#' Inputs: national_panel_2007_2010.parquet, prop census_id (geo read),
#'         focal_repeat_sales.parquet (08a), focal_subsequent_sales.parquet (08c),
#'         data/external/fhfa_state_hpi.parquet (HPI deflator)
#' Output: iv_shored_up.rds

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))
set.seed(20260606)
norm_id <- function(x) sub("\\.0+$", "", trimws(as.character(x)))
yr <- function(x) floor(as.numeric(norm_id(x)) / 10000)

# ---- focal panel ----
log_msg("Loading focal panel...")
panel <- read_parquet(path(data_dir, "national_panel_2007_2010.parquet")) |>
  mutate(clip_chr = norm_id(clip),
         sale_chr = norm_id(sale_derived_date),
         county_fips = norm_id(dplyr::coalesce(.data[["fips_code_prop"]],
                                               .data[["fips_code_ot"]])),
         county_int = suppressWarnings(as.integer(county_fips)),
         county5 = ifelse(is.na(county_int), NA_character_,
                          formatC(county_int, width = 5, flag = "0")),
         state_fips = substr(county5, 1, 2),
         sale_year = yr(sale_chr))

# ---- census tract (geo read; memory-frugal: keep only panel clips per state) ----
log_msg("Reading census_id (state-by-state, filtered to panel clips)...")
panel_clips <- unique(panel$clip_chr)
gc()
state_dirs <- fs::dir_ls(here::here("data/corelogic_extracts/by_state/prop"), type = "directory")
geo_list <- vector("list", length(state_dirs))
for (i in seq_along(state_dirs)) {
  part <- fs::path(state_dirs[i], "part.parquet")
  if (!fs::file_exists(part)) next
  df <- tryCatch(arrow::read_parquet(part, col_select = dplyr::any_of(c("clip","census_id"))),
                 error = function(e) NULL)
  if (is.null(df) || !all(c("clip","census_id") %in% names(df))) next
  cc  <- norm_id(df$clip); cid <- as.character(df$census_id)
  keep <- !is.na(cid) & cid != "" & cc %in% panel_clips
  if (any(keep)) geo_list[[i]] <- data.frame(clip_chr = cc[keep], census_id = cid[keep])
  if (i %% 12L == 0L) log_msg("  geo ", i, "/", length(state_dirs))
}
geo <- dplyr::bind_rows(geo_list) |> distinct(clip_chr, .keep_all = TRUE)
log_msg("Geo rows matched to panel: ", format(nrow(geo), big.mark = ","))
panel <- panel |>
  left_join(geo |> select(clip_chr, census_id), by = "clip_chr") |>
  mutate(tract6 = ifelse(nchar(census_id) >= 10L, substr(census_id, 1, 6), NA_character_),
         census_tract = ifelse(!is.na(tract6) & !is.na(county5), paste0(county5, tract6), NA_character_))

# ---- prior + subsequent sale prices ----
log_msg("Joining prior (08a) + subsequent (08c) sale prices...")
pri <- read_parquet(path(data_dir, "focal_repeat_sales.parquet")) |>
  transmute(clip_chr = norm_id(clip), sale_chr = norm_id(sale_raw),
            prior_price, prior_year = yr(prior_sale_raw))
nxt <- read_parquet(path(data_dir, "focal_subsequent_sales.parquet")) |>
  transmute(clip_chr = norm_id(clip), sale_chr = norm_id(sale_raw),
            next_price, next_year = yr(next_sale_raw))
panel <- panel |>
  left_join(pri, by = c("clip_chr","sale_chr")) |>
  left_join(nxt, by = c("clip_chr","sale_chr"))

# ---- HPI deflators (state-year) ----
hpi_path <- here::here("data/external/fhfa_state_hpi.parquet")
HAVE_HPI <- file.exists(hpi_path)
if (HAVE_HPI) {
  log_msg("Deflating repeat-sale prices by FHFA state-year HPI...")
  hpi <- read_parquet(hpi_path) |>
    mutate(state_fips = formatC(suppressWarnings(as.integer(state_fips)), width = 2, flag = "0"),
           year = as.integer(year), hpi = as.numeric(hpi)) |>
    select(state_fips, year, hpi)
  jn <- function(d, ycol, nm) {
    d |> left_join(hpi |> rename(!!nm := hpi),
                   by = c("state_fips" = "state_fips", setNames("year", ycol)))
  }
  panel <- panel |>
    jn("sale_year",  "hpi_focal") |>
    jn("prior_year", "hpi_prior") |>
    jn("next_year",  "hpi_next")
  # deflate to focal-year value terms: price * hpi_focal / hpi_other
  panel <- panel |>
    mutate(prior_defl = ifelse(!is.na(prior_price) & prior_price > 0 & hpi_prior > 0 & !is.na(hpi_focal),
                               prior_price * hpi_focal / hpi_prior, NA_real_),
           next_defl  = ifelse(!is.na(next_price) & next_price > 0 & hpi_next > 0 & !is.na(hpi_focal),
                               next_price * hpi_focal / hpi_next, NA_real_))
} else {
  log_msg("WARNING: FHFA HPI not found — using NOMINAL repeat-sale prices (no deflation).")
  panel <- panel |> mutate(prior_defl = prior_price, next_defl = next_price)
}

# ---- construct variables + filter ----
panel <- panel |>
  mutate(log_price = log(sale_amount),
         log_ratio = log(assessment_ratio),
         log_assessed = log_ratio + log_price,
         log_prior = ifelse(!is.na(prior_defl) & prior_defl > 0, log(prior_defl), NA_real_),
         log_next  = ifelse(!is.na(next_defl)  & next_defl  > 0, log(next_defl),  NA_real_)) |>
  filter(!is.na(census_tract), !is.na(county_fips), county_fips != "",
         sale_amount > 0, assessment_ratio > 0, is.finite(log_ratio))

# ---- spec runners ----
getb  <- function(m) { cf <- coef(m); unname(cf[grep("log_price", names(cf))][1]) }
getse <- function(m) { v <- sqrt(diag(vcov(m))); unname(v[grep("log_price", names(v))][1]) }
ivF   <- function(m) tryCatch(fitstat(m, "ivf")[[1]]$stat, error = function(e) NA_real_)

run_ols <- function(d, fe, yv, lab) {
  m <- feols(as.formula(sprintf("%s ~ log_price | %s", yv, fe)), data = d, cluster = ~county_fips)
  data.frame(spec = lab, outcome = yv, fe = fe, n = nobs(m),
             beta = unname(coef(m)["log_price"]),
             se = unname(sqrt(diag(vcov(m)))["log_price"]), F = NA_real_)
}
run_iv <- function(d, fe, yv, inst, lab) {
  m <- feols(as.formula(sprintf("%s ~ 1 | %s | log_price ~ %s", yv, fe, inst)),
             data = d, cluster = ~county_fips)
  data.frame(spec = lab, outcome = yv, fe = fe, n = nobs(m),
             beta = getb(m), se = getse(m), F = ivF(m))
}

d_pri   <- panel |> filter(!is.na(log_prior))
d_nxt   <- panel |> filter(!is.na(log_next))
d_both  <- panel |> filter(!is.na(log_prior), !is.na(log_next))
# Acquisition-value / cap-reset states leak the sale price into the assessed
# value (CA Prop 13, FL Save Our Homes, MI Proposal A), violating the
# repeat-sale instrument's exclusion restriction. Exclude them as a robustness.
CAP_STATES <- c("06","12","26")
d_both_nocap <- d_both |> filter(!(state_fips %in% CAP_STATES))
log_msg("Samples — prior: ", format(nrow(d_pri), big.mark=","),
        " | subsequent: ", format(nrow(d_nxt), big.mark=","),
        " | both: ", format(nrow(d_both), big.mark=","),
        " | both ex-cap: ", format(nrow(d_both_nocap), big.mark=","))

res <- dplyr::bind_rows(
  run_ols(d_both, "county_fips",  "log_ratio", "OLS"),
  run_ols(d_both, "census_tract", "log_ratio", "OLS"),
  run_iv (d_pri,  "county_fips",  "log_ratio", "log_prior", "IV prior"),
  run_iv (d_pri,  "census_tract", "log_ratio", "log_prior", "IV prior"),
  run_iv (d_nxt,  "county_fips",  "log_ratio", "log_next",  "IV subsequent"),
  run_iv (d_nxt,  "census_tract", "log_ratio", "log_next",  "IV subsequent"),
  run_iv (d_both, "county_fips",  "log_ratio", "log_prior + log_next", "IV both"),
  run_iv (d_both, "census_tract", "log_ratio", "log_prior + log_next", "IV both"),
  run_iv (d_both_nocap, "county_fips",  "log_ratio", "log_prior + log_next", "IV both (ex-cap)"),
  run_iv (d_both_nocap, "census_tract", "log_ratio", "log_prior + log_next", "IV both (ex-cap)"),
  # level-on-level gamma (regressivity = gamma < 1), IV both — the headline form
  run_iv (d_both, "county_fips",  "log_assessed", "log_prior + log_next", "IV both (level gamma)"),
  run_iv (d_both, "census_tract", "log_assessed", "log_prior + log_next", "IV both (level gamma)")
)

m_both_tract <- feols(log_ratio ~ 1 | census_tract | log_price ~ log_prior + log_next,
                      data = d_both, cluster = ~county_fips)
sargan <- tryCatch(fitstat(m_both_tract, "sargan")[[1]], error = function(e) NULL)

# ---- report ----
cat("\n\n========== SHORED-UP DIVISION-BIAS IV ==========\n")
cat("HPI deflation: ", if (HAVE_HPI) "YES (FHFA state-year)" else "NO (nominal)", "\n")
cat("beta = slope of log(assessment ratio) on log(price); negative = regressive.\n")
cat("gamma = slope of log(assessed) on log(price); regressivity = gamma < 1.\n")
cat("Decisive: does beta_tract < beta_county SURVIVE under IV?\n\n")
res$beta <- round(res$beta, 4); res$se <- round(res$se, 4); res$F <- round(res$F, 0)
print(res, row.names = FALSE)
if (!is.null(sargan))
  cat(sprintf("\nIV-both (tract) Hansen J overid: stat=%.2f, p=%.3f  (p>0.05 => instruments agree => valid)\n",
              sargan$stat, sargan$p))

saveRDS(list(results = res, sargan = sargan, have_hpi = HAVE_HPI,
             n_pri = nrow(d_pri), n_nxt = nrow(d_nxt), n_both = nrow(d_both)),
        path(out_dir, "iv_shored_up.rds"))
log_msg("DONE. Saved iv_shored_up.rds")
