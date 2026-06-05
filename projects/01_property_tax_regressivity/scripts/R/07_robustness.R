#' 07: RQ1 robustness — does the within-neighborhood result survive (a) trimming
#' thin tracts and (b) a distribution-free regressivity statistic?
#'
#' (1) Trim thin tracts: re-estimate the tract-FE slope on tracts with >= 20
#'     sales, to rule out that beta_tract is driven by sparsely-sampled tracts.
#' (2) Distribution-free: the size-weighted mean within-group Spearman rank
#'     correlation between log sale price and log assessment ratio, county vs
#'     tract. Rank-based, so immune to the mechanical bias of the regression
#'     regressivity measure flagged by McMillen & Singh (2023). A within-tract
#'     value at least as negative as the within-county value confirms the
#'     within-neighborhood finding without relying on the OLS slope.
#'
#' Input:  rq1_analytic_frame.parquet (cached by 05_tract_decomposition.R)
#' Output: rq1_robustness.rds

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))
set.seed(20260605)

frame_path <- path(data_dir, "rq1_analytic_frame.parquet")
if (!file.exists(frame_path))
  stop("rq1_analytic_frame.parquet not found — run 05_tract_decomposition.R first.")
d <- read_parquet(frame_path)
log_msg("Loaded analytic frame: ", format(nrow(d), big.mark = ","), " rows")

# ============================================================
# (1) Trim thin tracts
# ============================================================
d <- d |> add_count(census_tract, name = "n_t")
d20 <- d |> filter(n_t >= 20L)
log_msg("Tracts >= 20 sales: ", format(dplyr::n_distinct(d20$census_tract), big.mark = ","),
        " of ", format(dplyr::n_distinct(d$census_tract), big.mark = ","),
        " | rows: ", format(nrow(d20), big.mark = ","))

m_tract_full <- feols(log_assessment_ratio ~ log_sale_price | census_tract,
                      data = d,   cluster = ~county_fips)
m_tract_20   <- feols(log_assessment_ratio ~ log_sale_price | census_tract,
                      data = d20, cluster = ~county_fips)
b_full <- unname(coef(m_tract_full)["log_sale_price"])
b_20   <- unname(coef(m_tract_20)["log_sale_price"])

# ============================================================
# (2) Distribution-free: within-group Spearman rank correlation
# (immune to the OLS mechanical-bias critique; negative = regressive)
# ============================================================
wcorr <- function(df, g, min_n = 10L) {
  df |>
    group_by(.data[[g]]) |>
    filter(dplyr::n() >= min_n) |>
    summarise(rho = suppressWarnings(cor(log_sale_price, log_assessment_ratio,
                                         method = "spearman")),
              n = dplyr::n(), .groups = "drop") |>
    filter(is.finite(rho)) |>
    summarise(rho_bar = weighted.mean(rho, n)) |>
    pull(rho_bar)
}
log_msg("Computing within-county Spearman...")
rho_county <- wcorr(d, "county_fips")
log_msg("Computing within-tract Spearman...")
rho_tract  <- wcorr(d, "census_tract")

# ---- report ----
cat("\n\n========== RQ1 ROBUSTNESS ==========\n\n")
cat("(1) Trim thin tracts (census-tract FE slope):\n")
cat(sprintf("    all tracts         beta_tract = %+.4f (SE %.4f, N = %s)\n",
            b_full, unname(sqrt(diag(vcov(m_tract_full)))["log_sale_price"]),
            format(nobs(m_tract_full), big.mark = ",")))
cat(sprintf("    tracts >= 20 sales beta_tract = %+.4f (SE %.4f, N = %s)\n\n",
            b_20, unname(sqrt(diag(vcov(m_tract_20)))["log_sale_price"]),
            format(nobs(m_tract_20), big.mark = ",")))
cat("(2) Distribution-free regressivity (size-weighted mean within-group\n")
cat("    Spearman rank corr, log price vs log assessment ratio):\n")
cat(sprintf("    within county = %+.4f\n", rho_county))
cat(sprintf("    within tract  = %+.4f   (<= county confirms within-neighborhood)\n\n", rho_tract))

results <- list(
  b_tract_full = b_full, b_tract_trim20 = b_20,
  n_full = nobs(m_tract_full), n_trim20 = nobs(m_tract_20),
  rho_county = rho_county, rho_tract = rho_tract
)
saveRDS(results, path(out_dir, "rq1_robustness.rds"))
log_msg("DONE. Saved rq1_robustness.rds")
