#' 02: Replicate Berry (2021) — within-jurisdiction regressivity coefficient.
#'
#' Berry's main specification (from "Reassessing the Property Tax", March 2021 draft):
#'
#'   log(effective_tax_rate_{ij}) = alpha_j + beta * log(sale_price_{ij}) + e_{ij}
#'
#' where i indexes parcel-transaction, j indexes jurisdiction (county FIPS), and
#' alpha_j is the jurisdiction fixed effect. Within-jurisdiction elasticity of the
#' tax rate w.r.t. sale price is `beta`. Berry's headline estimate (paper intro,
#' national 2007-2017 sample): beta = -0.37, implying bottom-decile properties
#' pay more than 2x the effective tax rate of top-decile properties within the
#' same jurisdiction.
#'
#' We run the same specification on our national 2007-2010 sample (limited by
#' UC's CoreLogic prop snapshot vintage; see 01_clean.R header). Target
#' replication tolerance: |beta_ours - beta_Berry| < 0.05.
#'
#' Output: regression results saved to _outputs/; replication summary printed
#' for transcription into the replication report.

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

# ---- read panel ----
# Prefer national; fall back to smoke if national hasn't been built yet
national_rds <- path(out_dir, "national_panel_2007_2010.rds")
smoke_rds    <- path(out_dir, "sample_panel_for_smoke.rds")
panel_rds <- if (file.exists(national_rds)) national_rds else smoke_rds
if (!file.exists(panel_rds)) stop("No panel RDS found. Run 01_clean.R first.")
log_msg("Loading panel from: ", panel_rds)
panel <- readRDS(panel_rds)
log_msg("Panel rows: ", format(nrow(panel), big.mark = ","),
        ", cols: ", ncol(panel))

# ---- jurisdiction identifier ----
# Berry's "jurisdiction" is county-level. fips_code is 5-digit state+county FIPS.
# After the inner_join in 01_clean.R, both OT and Prop's fips_code became
# `fips_code_ot` and `fips_code_prop`. We prefer the PROP fips (assessor's
# tax jurisdiction), falling back to OT's transaction fips if prop is missing.
juris_col <- if ("fips_code_prop" %in% names(panel)) {
  "fips_code_prop"
} else if ("fips_code" %in% names(panel)) {
  "fips_code"
} else if ("fips_code_ot" %in% names(panel)) {
  "fips_code_ot"
} else if ("transaction_fips_code" %in% names(panel)) {
  "transaction_fips_code"
} else {
  stop("No FIPS column found for jurisdiction")
}
log_msg("Using jurisdiction column: ", juris_col)
panel <- panel |> mutate(jurisdiction = as.character(.data[[juris_col]]))

# Drop rows with missing jurisdiction
panel <- panel |> filter(!is.na(jurisdiction), jurisdiction != "")
log_msg("After jurisdiction filter: ", format(nrow(panel), big.mark = ","))

# ---- create regression variables ----
panel <- panel |>
  mutate(
    log_sale_price        = log(sale_amount),
    log_assessment_ratio  = log(assessment_ratio),
    log_effective_tax_rate = log(effective_tax_rate)
  )

# Diagnostic: how many jurisdictions, and what's the distribution of obs/juris
n_juris <- panel |> distinct(jurisdiction) |> nrow()
log_msg("Distinct jurisdictions: ", n_juris)
obs_per_juris <- panel |>
  count(jurisdiction) |>
  pull(n)
log_msg("Median obs per jurisdiction: ", median(obs_per_juris),
        " | min: ", min(obs_per_juris), " | max: ", max(obs_per_juris))

# Drop singleton jurisdictions (can't estimate FE)
panel <- panel |>
  group_by(jurisdiction) |>
  filter(n() >= 2) |>
  ungroup()
log_msg("After singleton drop: ", format(nrow(panel), big.mark = ","))

# ---- the regressions ----

# Model 1: Berry's primary specification — log(effective_tax_rate) on log(sale_price)
log_msg("Estimating Model 1: log(effective_tax_rate) ~ log(sale_price) | jurisdiction")
m1 <- tryCatch({
  feols(
    log_effective_tax_rate ~ log_sale_price | jurisdiction,
    data    = panel |> filter(!is.na(log_effective_tax_rate),
                              is.finite(log_effective_tax_rate)),
    cluster = "jurisdiction"
  )
}, error = function(e) {
  log_msg("  Model 1 failed: ", conditionMessage(e))
  NULL
})

# Model 2: same on assessment_ratio (Berry's alternative; should give same beta
# within-jurisdiction since tax_rate = mill_rate * assessment_ratio, and
# mill_rate is jurisdiction-specific, absorbed by alpha_j)
log_msg("Estimating Model 2: log(assessment_ratio) ~ log(sale_price) | jurisdiction")
m2 <- feols(
  log_assessment_ratio ~ log_sale_price | jurisdiction,
  data    = panel,
  cluster = "jurisdiction"
)

# Model 3: pooled (no FE) — for comparison; shows across-juris vs within-juris
log_msg("Estimating Model 3 (pooled, no FE): log(assessment_ratio) ~ log(sale_price)")
m3 <- feols(log_assessment_ratio ~ log_sale_price, data = panel)

# ---- report ----
cat("\n\n========== BERRY REPLICATION RESULTS ==========\n")
cat("Sample: ", format(nrow(panel), big.mark = ","), " parcel-transactions, ",
    n_juris, " jurisdictions\n")
cat("Sale-year window: ", min(panel$sale_year), "-", max(panel$sale_year), "\n\n")

cat("BERRY (2021): within-jurisdiction beta = -0.37 (national 2007-2017)\n\n")

if (!is.null(m1)) {
  beta_m1 <- coef(m1)["log_sale_price"]
  se_m1   <- sqrt(diag(vcov(m1)))["log_sale_price"]
  cat(sprintf("  Model 1 (effective_tax_rate):  beta = %+.4f  (SE = %.4f)\n",
              beta_m1, se_m1))
}
beta_m2 <- coef(m2)["log_sale_price"]
se_m2   <- sqrt(diag(vcov(m2)))["log_sale_price"]
cat(sprintf("  Model 2 (assessment_ratio):    beta = %+.4f  (SE = %.4f)\n",
            beta_m2, se_m2))

beta_m3 <- coef(m3)["log_sale_price"]
se_m3   <- sqrt(diag(vcov(m3)))["log_sale_price"]
cat(sprintf("  Model 3 (pooled, no FE):       beta = %+.4f  (SE = %.4f)\n",
            beta_m3, se_m3))

cat("\nReplication tolerance: |beta_ours - (-0.37)| < 0.05\n")
target <- -0.37
beta_main <- if (!is.null(m1)) beta_m1 else beta_m2
diff <- abs(beta_main - target)
status <- if (diff < 0.05) "PASS" else if (diff < 0.10) "MARGINAL" else "FAIL"
cat(sprintf("Difference from target: %+.4f  ->  %s\n\n", beta_main - target, status))

# ---- save ----
results <- list(
  m1_effective_tax_rate = m1,
  m2_assessment_ratio   = m2,
  m3_pooled             = m3,
  sample_size           = nrow(panel),
  n_jurisdictions       = n_juris,
  sale_year_range       = range(panel$sale_year),
  target_berry          = target,
  diff_from_target      = if (!is.null(m1)) beta_m1 - target else beta_m2 - target,
  status                = status
)
saveRDS(results, path(out_dir, "berry_replication_results.rds"))

log_msg("DONE. Results saved to: ", path(out_dir, "berry_replication_results.rds"))
