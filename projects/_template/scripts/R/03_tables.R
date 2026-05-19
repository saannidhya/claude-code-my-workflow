#' 03: Generate manuscript tables.

source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))
library(modelsummary)

results <- readRDS(fs::path(out_dir, "regression_results.rds"))

# Main results table -> LaTeX
msummary(
  results,
  output    = fs::path(tables_dir, "T2_main_results.tex"),
  stars     = TRUE,
  gof_omit  = "AIC|BIC|RMSE|Within|Pseudo",
  coef_map  = c("BEDROOMS" = "Bedrooms",
                "BATHROOMS" = "Bathrooms",
                "LIVING_AREA" = "Living area (sqft)")
)

cat("Tables written to: ", tables_dir, "\n", sep = "")
