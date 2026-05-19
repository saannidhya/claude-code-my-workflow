#' 01: Load + clean CoreLogic data for this project.

source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))

# Development: use sample first
USE_SAMPLE <- TRUE  # flip to FALSE for final run

ot <- load_corelogic_ot(
  states  = c("OH"),                # TODO: set states for this project
  years   = 2018:2024,               # TODO: set years
  columns = c("APN", "SALE_AMOUNT", "SALE_DATE"),  # TODO: select columns needed
  sample  = USE_SAMPLE
)

prop <- load_corelogic_prop(
  states  = c("OH"),
  columns = c("APN", "BEDROOMS", "BATHROOMS", "LIVING_AREA"),
  sample  = USE_SAMPLE
)

# Common arms-length cleaner
ot_clean <- filter_arms_length(ot, min_price = 5000)

# Join transactions to property characteristics
sample_panel <- ot_clean |>
  left_join(prop, by = "APN")

# Save derived data
write_parquet(sample_panel, fs::path(data_dir, "sample_panel.parquet"))
saveRDS(sample_panel, fs::path(out_dir, "sample_panel.rds"))

cat("Clean: ", nrow(sample_panel), " rows written.\n", sep = "")
