#' 08: Division-bias IV — is the within-neighborhood regressivity real or an
#' artifact of price measurement error?
#'
#' The peer review (quality_reports/peer_review_paper/editorial_decision.md)
#' identified the binding threat: the assessment ratio = assessed/price is
#' regressed on price, so transitory price noise mechanically tilts the slope
#' negative, and within-tract (noisier price) amplifies it -> the -0.41->-0.52
#' steepening could be artifact, not "neighborhood anchoring."
#'
#' Fix: instrument the focal log price with a measure orthogonal to the focal
#' sale's transitory noise. Three instruments with different failure modes:
#'   (1) PRIOR arms-length sale price (deflated via year FE + gap control)
#'   (2) HEDONIC predicted value (characteristics only)
#'   (3) MULTI (both) -> Hansen J overidentification test
#' For each: OLS vs IV, county FE vs tract FE, on a COMMON sample. The decisive
#' question is whether beta_tract < beta_county SURVIVES under IV.
#'
#' Inputs: national_panel_2007_2010.parquet, prop census_id (geo read),
#'         focal_repeat_sales.parquet (08a), characteristics.parquet (08b)
#' Output: iv_division_bias.rds

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))
set.seed(20260606)
norm_id <- function(x) sub("\\.0+$", "", trimws(as.character(x)))

# ---- focal panel ----
log_msg("Loading focal panel...")
panel <- read_parquet(path(data_dir, "national_panel_2007_2010.parquet")) |>
  mutate(clip_chr = norm_id(clip),
         sale_chr = norm_id(sale_derived_date),
         county_fips = norm_id(dplyr::coalesce(.data[["fips_code_prop"]],
                                               .data[["fips_code_ot"]])),
         sale_year = floor(as.numeric(sale_chr) / 10000))

# ---- census tract (geo read; mirrors 05_tract_decomposition.R) ----
log_msg("Reading census_id (state-by-state)...")
prop_root  <- here::here("data/corelogic_extracts/by_state/prop")
state_dirs <- fs::dir_ls(prop_root, type = "directory")
geo_list <- vector("list", length(state_dirs))
for (i in seq_along(state_dirs)) {
  part <- fs::path(state_dirs[i], "part.parquet")
  if (!fs::file_exists(part)) next
  df <- tryCatch(arrow::read_parquet(part, col_select = dplyr::any_of(c("clip","census_id"))),
                 error = function(e) NULL)
  if (is.null(df) || !all(c("clip","census_id") %in% names(df))) next
  df$clip <- as.character(df$clip); df$census_id <- as.character(df$census_id)
  geo_list[[i]] <- df
}
geo <- dplyr::bind_rows(geo_list) |>
  filter(!is.na(census_id), census_id != "") |>
  mutate(clip_chr = norm_id(clip)) |>
  distinct(clip_chr, .keep_all = TRUE)

panel <- panel |>
  left_join(geo |> select(clip_chr, census_id), by = "clip_chr") |>
  mutate(county5 = ifelse(is.na(suppressWarnings(as.integer(county_fips))), NA_character_,
                          formatC(as.integer(county_fips), width = 5, flag = "0")),
         tract6  = ifelse(nchar(census_id) >= 10L, substr(census_id, 1, 6), NA_character_),
         census_tract = ifelse(!is.na(tract6) & !is.na(county5),
                               paste0(county5, tract6), NA_character_))

# ---- prior arms-length sale price (08a), by clip + focal sale date ----
log_msg("Joining prior-sale prices (08a)...")
rs <- read_parquet(path(data_dir, "focal_repeat_sales.parquet")) |>
  transmute(clip_chr = norm_id(clip),
            sale_chr = norm_id(sale_raw),
            prior_price, prior_sale_raw)
panel <- panel |> left_join(rs, by = c("clip_chr", "sale_chr"))

# ---- characteristics (08b), by clip ----
log_msg("Joining characteristics (08b)...")
ch <- read_parquet(path(data_dir, "characteristics.parquet"))
panel <- panel |> left_join(ch, by = "clip_chr")

# ---- construct variables ----
log_msg("Constructing analysis variables...")
panel <- panel |>
  mutate(
    log_price  = log(sale_amount),
    log_ratio  = log(assessment_ratio),
    log_assessed = log_ratio + log_price,                 # = log(assessed value)
    log_prior  = ifelse(!is.na(prior_price) & prior_price > 0, log(prior_price), NA_real_),
    gap_years  = sale_year - floor(as.numeric(norm_id(prior_sale_raw)) / 10000),
    age        = pmax(sale_year - yrbuilt, 0),
    log_living = ifelse(!is.na(living) & living > 0, log(living), NA_real_),
    log_lot    = ifelse(!is.na(lot) & lot > 0, log(lot), NA_real_)
  ) |>
  filter(!is.na(census_tract), !is.na(county_fips), county_fips != "",
         sale_amount > 0, assessment_ratio > 0, is.finite(log_ratio))

# ---- HEDONIC first stage: characteristics-only predicted value ----
log_msg("Fitting hedonic value proxy (characteristics only)...")
hed_data <- panel |>
  filter(!is.na(log_living), !is.na(age), !is.na(beds), !is.na(baths))
hedonic <- feols(log_price ~ log_living + age + I(age^2) + beds + baths +
                   log_lot + stories, data = hed_data)
panel$log_hedonic <- predict(hedonic, newdata = panel)
hed_r2 <- tryCatch(unname(r2(hedonic, "r2")), error = function(e) NA_real_)
log_msg("Hedonic R2 = ", round(hed_r2, 3),
        " | predictable rows: ", format(sum(!is.na(panel$log_hedonic)), big.mark = ","))

# ---- spec runner ----
getb  <- function(m) { cf <- coef(m); unname(cf[grep("log_price", names(cf))][1]) }
getse <- function(m) { v <- sqrt(diag(vcov(m))); unname(v[grep("log_price", names(v))][1]) }
ivF   <- function(m) tryCatch(fitstat(m, "ivf")[[1]]$stat, error = function(e) NA_real_)

run_iv <- function(d, fe, inst, label) {
  fml <- as.formula(sprintf("log_ratio ~ 1 | %s | log_price ~ %s", fe, inst))
  m <- feols(fml, data = d, cluster = ~county_fips)
  data.frame(spec = label, fe = fe, n = nobs(m),
             beta = getb(m), se = getse(m), first_stage_F = ivF(m))
}
run_ols <- function(d, fe, label) {
  m <- feols(as.formula(sprintf("log_ratio ~ log_price | %s", fe)),
             data = d, cluster = ~county_fips)
  data.frame(spec = label, fe = fe, n = nobs(m),
             beta = unname(coef(m)["log_price"]),
             se = unname(sqrt(diag(vcov(m)))["log_price"]), first_stage_F = NA_real_)
}

# samples
d_prior <- panel |> filter(!is.na(log_prior), gap_years > 0, gap_years <= 40)
d_hed   <- panel |> filter(!is.na(log_hedonic))
d_multi <- panel |> filter(!is.na(log_prior), gap_years > 0, gap_years <= 40, !is.na(log_hedonic))
log_msg("Samples — prior: ", format(nrow(d_prior), big.mark=","),
        " | hedonic: ", format(nrow(d_hed), big.mark=","),
        " | multi: ", format(nrow(d_multi), big.mark=","))

res <- dplyr::bind_rows(
  # OLS baselines on each sample
  run_ols(d_prior, "county_fips",  "OLS (prior-sample)"),
  run_ols(d_prior, "census_tract", "OLS (prior-sample)"),
  run_ols(d_hed,   "county_fips",  "OLS (hedonic-sample)"),
  run_ols(d_hed,   "census_tract", "OLS (hedonic-sample)"),
  # IV: prior-sale-price instrument
  run_iv(d_prior, "county_fips",  "log_prior", "IV prior-sale"),
  run_iv(d_prior, "census_tract", "log_prior", "IV prior-sale"),
  # IV: hedonic instrument
  run_iv(d_hed,   "county_fips",  "log_hedonic", "IV hedonic"),
  run_iv(d_hed,   "census_tract", "log_hedonic", "IV hedonic"),
  # IV: multi (both) on intersection
  run_iv(d_multi, "county_fips",  "log_prior + log_hedonic", "IV multi"),
  run_iv(d_multi, "census_tract", "log_prior + log_hedonic", "IV multi")
)

# Hansen/Sargan overid for the multi-IV tract spec
m_multi_tract <- feols(log_ratio ~ 1 | census_tract | log_price ~ log_prior + log_hedonic,
                       data = d_multi, cluster = ~county_fips)
sargan <- tryCatch(fitstat(m_multi_tract, "sargan")[[1]], error = function(e) NULL)

# ---- report ----
cat("\n\n========== DIVISION-BIAS IV ==========\n")
cat("Beta = slope of log(assessment ratio) on log(price). Negative = regressive.\n")
cat("Decisive: does beta_tract < beta_county SURVIVE under IV?\n\n")
res$beta <- round(res$beta, 4); res$se <- round(res$se, 4)
res$first_stage_F <- round(res$first_stage_F, 1)
print(res, row.names = FALSE)
if (!is.null(sargan))
  cat(sprintf("\nMulti-IV (tract) Hansen/Sargan overid: stat=%.2f p=%.3f  (high p = instruments agree)\n",
              sargan$stat, sargan$p))

saveRDS(list(results = res, hedonic = hedonic, sargan = sargan,
             n_prior = nrow(d_prior), n_hed = nrow(d_hed), n_multi = nrow(d_multi)),
        path(out_dir, "iv_division_bias.rds"))
log_msg("DONE. Saved iv_division_bias.rds")
