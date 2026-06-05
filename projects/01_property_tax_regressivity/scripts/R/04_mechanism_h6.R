#' 04: H6 mechanism test — does transaction frequency MEDIATE regressivity?
#'
#' H6: parcels that transact more frequently (or more recently) give the
#' assessor fresher market signals, so their assessment ratios sit closer to
#' 1.0. If price level correlates with transaction frequency/recency, then
#' frequency partially explains the within-jurisdiction regressivity from
#' Phase 1 (base coefficient c = -0.42 on log assessment ratio).
#'
#' Design: a covariate (mediator) decomposition in the spirit of Gelbach
#' (2016, J. Labor Economics) "When do covariates matter?". We ask how much
#' the base price coefficient shrinks when we add the frequency/staleness
#' measure. The change (c - c') is the part of the price->ratio relationship
#' that operates THROUGH the mediator.
#'
#' Two mediators:
#'   (1) years_since_prior_sale  PRIMARY — strictly backward-looking staleness
#'       (gap between focal 2007-2010 sale and the immediately prior sale).
#'       Defined only for repeat-sale parcels (selected subsample; flagged).
#'   (2) n_txn_total             SECONDARY — count of all recorded sales per
#'       clip. Rougher: includes post-focal sales (forward-looking
#'       contamination), so descriptive only.
#'
#' CAUSAL CAVEAT (for the paper): treating frequency as a mediator assumes it
#' is not a collider on an unobserved path between price and assessment error.
#' We report this as a descriptive decomposition, not a causal mediation claim.
#' The structural model (Phase 3) is where the causal mechanism is identified.
#'
#' Inputs:  national_panel_2007_2010.parquet (Phase 1),
#'          clip_frequency.parquet + focal_txn_lag.parquet (script 03)
#' Output:  h6_mediation_results.rds

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

# ---- load panel + frequency measures ----
log_msg("Loading panel + frequency measures...")
panel <- read_parquet(path(data_dir, "national_panel_2007_2010.parquet"))
freq  <- read_parquet(path(data_dir, "clip_frequency.parquet"))
lag   <- read_parquet(path(data_dir, "focal_txn_lag.parquet"))
log_msg("Panel: ", format(nrow(panel), big.mark = ","),
        " | freq: ", format(nrow(freq), big.mark = ","),
        " | lag: ", format(nrow(lag), big.mark = ","))

# ---- type-safe join keys (CHARACTER, normalized) ----
# CRITICAL BUG HISTORY (2026-05-31): the panel stores clip as numeric (double)
# while the duckdb outputs stored it as VARCHAR cast from a double, leaving a
# ".0" suffix (e.g. "2780881868.0"). as.character(clip) on the panel gives
# "2780881868" (no suffix), so the keys never matched -> ZERO repeat-sale rows
# -> a regression that errored -> fabricated results. Script 03 now casts clip
# via BIGINT first; this helper additionally strips any residual ".0" so the
# join is robust to either cached-file vintage. NEVER trust a bare
# as.character() on a numeric ID again.
norm_id <- function(x) sub("\\.0+$", "", trimws(as.character(x)))

panel <- panel |>
  mutate(
    clip_chr = norm_id(clip),
    sale_chr = norm_id(sale_derived_date)  # YYYYMMDD as character
  )
freq <- freq |> mutate(clip_chr = norm_id(clip))
lag  <- lag  |> mutate(clip_chr = norm_id(clip),
                       sale_chr = norm_id(sale_raw))

# ---- merge ----
log_msg("Merging frequency (by clip) and lag (by clip + sale date)...")
panel <- panel |>
  left_join(freq |> select(clip_chr, n_txn_total, first_sale_raw, last_sale_raw),
            by = "clip_chr") |>
  left_join(lag |> select(clip_chr, sale_chr, prior_sale_raw),
            by = c("clip_chr", "sale_chr"))
log_msg("Post-merge rows: ", format(nrow(panel), big.mark = ","))
log_msg("Post-merge non-NA prior_sale_raw: ",
        format(sum(!is.na(panel$prior_sale_raw)), big.mark = ","))

# ---- construct mediator variables ----
panel <- panel |>
  mutate(
    # MAJOR-3 fix (code review 2026-06-05): day-level staleness, not year-
    # truncation. floor(YYYYMMDD/10000) quantized the gap to +/-1 year and
    # forced same-calendar-year repeats to 0. Compute from full dates instead.
    sale_date_v   = as.Date(sale_chr, format = "%Y%m%d"),
    prior_date_v  = as.Date(norm_id(prior_sale_raw), format = "%Y%m%d"),
    years_since_prior_sale = as.numeric(sale_date_v - prior_date_v) / 365.25,
    has_prior     = !is.na(prior_sale_raw),
    jurisdiction  = as.character(
      dplyr::coalesce(.data[["fips_code_prop"]], .data[["fips_code_ot"]])
    ),
    log_sale_price       = log(sale_amount),
    log_assessment_ratio = log(assessment_ratio),
    log_n_txn            = log(n_txn_total)
  )

# Sanity on years_since_prior (drop implausible negatives / >150)
panel <- panel |>
  mutate(years_since_prior_sale = ifelse(
    has_prior & years_since_prior_sale >= 0 & years_since_prior_sale <= 150,
    years_since_prior_sale, NA_real_
  ))

# Drop singleton jurisdictions + missing keys
panel <- panel |>
  filter(!is.na(jurisdiction), jurisdiction != "") |>
  group_by(jurisdiction) |> filter(n() >= 2) |> ungroup()

n_repeat <- sum(!is.na(panel$years_since_prior_sale))
log_msg("Analytic rows: ", format(nrow(panel), big.mark = ","),
        " | with prior sale (repeat-sale subsample): ",
        format(n_repeat, big.mark = ","),
        " (", round(100 * n_repeat / nrow(panel), 1), "%)")

# HARD GUARD (added after the 2026-05-31 fabrication incident): never let an
# empty/degenerate subsample slide silently into a regression. If the
# repeat-sale join produced almost nothing, the keys are mismatched again —
# stop loudly instead of erroring deep in feols (which is what got papered
# over with fabricated numbers last time).
if (n_repeat < 1000L) {
  stop("Repeat-sale subsample is empty/degenerate (n_repeat = ", n_repeat,
       "). The clip+date join likely failed — check key normalization. ",
       "Refusing to proceed.")
}

# ===================================================================
# LINK A: does price predict the mediator? (price -> frequency/staleness)
# ===================================================================
log_msg("LINK A: mediator ~ log(sale_price) | jurisdiction")
repeat_panel <- panel |> filter(!is.na(years_since_prior_sale))

a_staleness <- feols(years_since_prior_sale ~ log_sale_price | jurisdiction,
                     data = repeat_panel, cluster = "jurisdiction")
a_freq      <- feols(log_n_txn ~ log_sale_price | jurisdiction,
                     data = panel |> filter(!is.na(log_n_txn)),
                     cluster = "jurisdiction")

# ===================================================================
# PRIMARY mediator: years_since_prior_sale
# Run base and mediated on the SAME repeat-sale subsample for comparability.
# ===================================================================
log_msg("PRIMARY decomposition on repeat-sale subsample (staleness mediator)")
c_base_rs <- feols(log_assessment_ratio ~ log_sale_price | jurisdiction,
                   data = repeat_panel, cluster = "jurisdiction")
c_med_rs  <- feols(log_assessment_ratio ~ log_sale_price + years_since_prior_sale | jurisdiction,
                   data = repeat_panel, cluster = "jurisdiction")

# ===================================================================
# SECONDARY mediator: n_txn_total (full sample, descriptive)
# ===================================================================
log_msg("SECONDARY decomposition on full sample (n_txn mediator)")
full_freq <- panel |> filter(!is.na(log_n_txn))
c_base_full <- feols(log_assessment_ratio ~ log_sale_price | jurisdiction,
                     data = full_freq, cluster = "jurisdiction")
c_med_full  <- feols(log_assessment_ratio ~ log_sale_price + log_n_txn | jurisdiction,
                     data = full_freq, cluster = "jurisdiction")

# ---- report ----
get_b <- function(m, v = "log_sale_price") unname(coef(m)[v])
get_se <- function(m, v = "log_sale_price") unname(sqrt(diag(vcov(m)))[v])

cat("\n\n========== H6: TRANSACTION-FREQUENCY MEDIATION ==========\n\n")

cat("LINK A — does price predict the mediator? (within jurisdiction)\n")
cat(sprintf("  years_since_prior_sale ~ log(price):  %+.4f (SE %.4f)   [%s]\n",
            get_b(a_staleness), get_se(a_staleness),
            ifelse(get_b(a_staleness) > 0, "pricier homes sell LESS often",
                   "pricier homes sell MORE often")))
cat(sprintf("  log(n_txn_total)       ~ log(price):  %+.4f (SE %.4f)\n\n",
            get_b(a_freq), get_se(a_freq)))

cat("PRIMARY decomposition (repeat-sale subsample, N = ",
    format(nrow(repeat_panel), big.mark = ","), ")\n", sep = "")
cb <- get_b(c_base_rs); cm <- get_b(c_med_rs)
cat(sprintf("  Base   c  : log(ratio) ~ log(price)                  = %+.4f (SE %.4f)\n",
            cb, get_se(c_base_rs)))
cat(sprintf("  Mediated c': + years_since_prior_sale                = %+.4f (SE %.4f)\n",
            cm, get_se(c_med_rs)))
cat(sprintf("  Mediator coef (years_since_prior on log ratio)       = %+.5f (SE %.5f)\n",
            get_b(c_med_rs, "years_since_prior_sale"),
            get_se(c_med_rs, "years_since_prior_sale")))
share_rs <- (cb - cm) / cb
cat(sprintf("  Share of regressivity mediated: (c - c')/c           = %.1f%%\n\n",
            100 * share_rs))

cat("SECONDARY decomposition (full sample, n_txn mediator, N = ",
    format(nrow(full_freq), big.mark = ","), ")\n", sep = "")
cbf <- get_b(c_base_full); cmf <- get_b(c_med_full)
cat(sprintf("  Base   c  : log(ratio) ~ log(price)                  = %+.4f (SE %.4f)\n",
            cbf, get_se(c_base_full)))
cat(sprintf("  Mediated c': + log(n_txn_total)                      = %+.4f (SE %.4f)\n",
            cmf, get_se(c_med_full)))
cat(sprintf("  Mediator coef (log n_txn on log ratio)               = %+.5f (SE %.5f)\n",
            get_b(c_med_full, "log_n_txn"), get_se(c_med_full, "log_n_txn")))
share_full <- (cbf - cmf) / cbf
cat(sprintf("  Share of regressivity mediated: (c - c')/c           = %.1f%%\n\n",
            100 * share_full))

cat("INTERPRETATION GUIDE:\n")
cat("  - Positive 'share mediated' => frequency/staleness explains part of\n")
cat("    the regressivity (c' closer to 0 than c). Supports H6.\n")
cat("  - ~0 or negative share => frequency does NOT explain regressivity;\n")
cat("    Berry's info-asymmetry story would need a different channel.\n\n")

# ---- save ----
results <- list(
  link_a_staleness = a_staleness, link_a_freq = a_freq,
  primary_base = c_base_rs, primary_mediated = c_med_rs, primary_share = share_rs,
  secondary_base = c_base_full, secondary_mediated = c_med_full, secondary_share = share_full,
  n_analytic = nrow(panel), n_repeat = nrow(repeat_panel), n_full_freq = nrow(full_freq)
)
saveRDS(results, path(out_dir, "h6_mediation_results.rds"))
log_msg("DONE. Saved h6_mediation_results.rds")
