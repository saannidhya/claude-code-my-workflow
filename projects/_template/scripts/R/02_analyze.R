#' 02: Main regressions / analysis.

source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))
library(fixest)

panel <- readRDS(fs::path(out_dir, "sample_panel.rds"))

# Example: hedonic price regression
mod_baseline <- feols(
  log(SALE_AMOUNT) ~ BEDROOMS + BATHROOMS + LIVING_AREA | year,
  data    = panel,
  cluster = "APN"
)

mod_extended <- feols(
  log(SALE_AMOUNT) ~ BEDROOMS + BATHROOMS + LIVING_AREA + i(year) | APN,
  data    = panel,
  cluster = "APN"
)

results <- list(
  baseline = mod_baseline,
  extended = mod_extended
)
saveRDS(results, fs::path(out_dir, "regression_results.rds"))

cat("Analyze: ", length(results), " models saved.\n", sep = "")
