#' 02: Main regressions / analysis.

source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))
library(fixest)

panel <- readRDS(fs::path(out_dir, "sample_panel.rds"))

# Example: hedonic price regression (snake_case CoreLogic schema post normalize_cols)
mod_baseline <- feols(
  log(sale_amount) ~ bedrooms + bathrooms + living_area | year,
  data    = panel,
  cluster = "clip"
)

mod_extended <- feols(
  log(sale_amount) ~ bedrooms + bathrooms + living_area + i(year) | clip,
  data    = panel,
  cluster = "clip"
)

results <- list(
  baseline = mod_baseline,
  extended = mod_extended
)
saveRDS(results, fs::path(out_dir, "regression_results.rds"))

cat("Analyze: ", length(results), " models saved.\n", sep = "")
