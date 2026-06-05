#' 06: Assemble key results tables + figures for the manuscript.
#'
#' Loads pre-computed RDS (heavy estimation already done in 02/04/05) and renders
#' publication-ready LaTeX tables + PDF figures into manuscript/{tables,figures}/.
#' Rendering only — no estimation here.
#'
#' Produces:
#'   tables/table1_main_decomposition.tex  — pooled -> county FE -> tract FE
#'   tables/table2_h6_mediation.tex        — transaction-frequency null (Gelbach)
#'   figures/fig1_decomposition.pdf        — coefficient plot of the FE ladder

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))
set.seed(20260605)
suppressPackageStartupMessages(library(modelsummary))
# Render clean booktabs LaTeX (\begin{tabular}, not tabularray) with plain numbers,
# so the manuscript preamble needs only \usepackage{booktabs}.
options(modelsummary_factory_latex = "kableExtra")
options("modelsummary_format_numeric_latex" = "plain")

dir_create(tables_dir); dir_create(figures_dir)
NAVY <- "#012169"

# ---- load results ----
berry <- readRDS(path(out_dir, "berry_replication_results.rds"))
h6    <- readRDS(path(out_dir, "h6_mediation_results.rds"))
rq1   <- readRDS(path(out_dir, "rq1_tract_decomposition.rds"))

bse <- function(m) c(b = unname(coef(m)["log_sale_price"]),
                     se = unname(sqrt(diag(vcov(m)))["log_sale_price"]))

# ============================================================
# TABLE 1 — main regressivity + spatial decomposition
# ============================================================
log_msg("Table 1: main decomposition")
t1 <- list(
  "(1) Pooled"               = berry$m3_pooled,
  "(2) County FE (full)"     = berry$m2_assessment_ratio,
  "(3) County FE (tract s.)" = rq1$m_county,
  "(4) Tract FE"             = rq1$m_tract
)
t1_rows <- tibble::tribble(
  ~term,            ~`(1) Pooled`, ~`(2) County FE (full)`, ~`(3) County FE (tract s.)`, ~`(4) Tract FE`,
  "Fixed effects",  "None",        "County",                 "County",                     "Tract"
)
attr(t1_rows, "position") <- 3

modelsummary(
  t1,
  output   = path(tables_dir, "table1_main_decomposition.tex"),
  coef_map = c(log_sale_price = "log(Sale price)"),
  gof_map  = c("nobs", "r.squared"),
  gof_omit = "AIC|BIC|RMSE|Log.Lik|Std.Errors|R2 Adj|R2 Within|FE:",
  add_rows = t1_rows,
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  title    = "Within-jurisdiction regressivity and its spatial decomposition",
  notes    = "DV: log(assessment ratio). SE clustered by county in FE columns. Cols (3)-(4) use the identical tract-covered subsample: adding tract FE moves the slope from -0.41 to -0.52, so regressivity intensifies within neighborhoods."
)

# ============================================================
# TABLE 2 — H6 transaction-frequency mediation (null)
# ============================================================
log_msg("Table 2: H6 mediation null")
t2 <- list(
  "(1) Base"        = h6$primary_base,
  "(2) + Staleness" = h6$primary_mediated,
  "(3) Base"        = h6$secondary_base,
  "(4) + Turnover"  = h6$secondary_mediated
)
share_row <- tibble::tribble(
  ~term,                    ~`(1) Base`, ~`(2) + Staleness`, ~`(3) Base`, ~`(4) + Turnover`,
  "Share mediated (pct.)",  "",          "0.0",               "",          "0.5"
)
attr(share_row, "position") <- 7

modelsummary(
  t2,
  output   = path(tables_dir, "table2_h6_mediation.tex"),
  coef_map = c(log_sale_price       = "log(Sale price)",
               years_since_prior_sale = "Years since prior sale",
               log_n_txn            = "log(N transactions)"),
  gof_map  = c("nobs"),
  gof_omit = "AIC|BIC|RMSE|Log.Lik|Std.Errors|R2|FE:",
  add_rows = share_row,
  stars    = c("*" = .05, "**" = .01, "***" = .001),
  title    = "H6: transaction frequency does not mediate regressivity (Gelbach decomposition)",
  notes    = "DV: log(assessment ratio), county FE, SE clustered by county. Cols (1)-(2): staleness mediator on the repeat-sale subsample. Cols (3)-(4): turnover mediator (descriptive; forward-looking). The base price slope is unchanged by either mediator."
)

# ---- inject \label into each table caption (so the paper can \ref them) ----
add_label <- function(file, lab) {
  x <- readLines(file)
  i <- grep("\\\\caption\\{", x)[1]
  if (!is.na(i)) { x[i] <- paste0(x[i], "\\label{", lab, "}"); writeLines(x, file) }
}
add_label(path(tables_dir, "table1_main_decomposition.tex"), "tab:decomp")
add_label(path(tables_dir, "table2_h6_mediation.tex"),       "tab:h6")

# ============================================================
# FIGURE 1 — coefficient plot of the FE ladder
# ============================================================
log_msg("Figure 1: decomposition coefficient plot")
mk <- function(m, lab) {
  v <- bse(m); tibble::tibble(spec = lab, b = v["b"], se = v["se"])
}
cf <- dplyr::bind_rows(
  mk(berry$m3_pooled,            "Pooled\n(no FE)"),
  mk(berry$m2_assessment_ratio, "County FE\n(Berry)"),
  mk(rq1$m_county,              "County FE\n(tract sample)"),
  mk(rq1$m_tract,               "Tract FE")
) |> dplyr::mutate(spec = factor(spec, levels = spec))

p <- ggplot(cf, aes(spec, b)) +
  geom_hline(yintercept = 0, colour = "grey75") +
  geom_pointrange(aes(ymin = b - 1.96 * se, ymax = b + 1.96 * se),
                  colour = NAVY, linewidth = 0.9, size = 0.6) +
  geom_text(aes(label = sprintf("%.2f", b)), vjust = -1.1, size = 3.4, colour = NAVY) +
  labs(x = NULL,
       y = "Elasticity of assessment ratio\nw.r.t. sale price",
       title = "Regressivity strengthens as the comparison narrows to the neighborhood",
       subtitle = "Within-jurisdiction price-regressivity, by fixed-effects specification (95% CI)") +
  coord_cartesian(ylim = c(min(cf$b - 2 * cf$se) - 0.03, 0.02))

ggsave(path(figures_dir, "fig1_decomposition.pdf"), p, width = 7.5, height = 4.5)

log_msg("DONE. Wrote 2 tables + 1 figure to manuscript/{tables,figures}/")
