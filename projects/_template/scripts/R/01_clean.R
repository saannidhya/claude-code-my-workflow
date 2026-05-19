#' 01: Load + clean CoreLogic data for this project.

source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))

# Development: use sample first
USE_SAMPLE <- TRUE  # flip to FALSE for final run

ot <- load_corelogic_ot(
  states  = c("OH"),                # TODO: set states for this project
  years   = 2018:2024,               # TODO: set years (year-partitioned if conversion detected a date column)
  # Column names after normalize_cols() are snake_case. Use clip + price + date as a minimal panel.
  columns = c("clip", "apn_parcel_number_unformatted", "sale_amount", "sale_derived_date"),
  sample  = USE_SAMPLE
)

prop <- load_corelogic_prop(
  states  = c("OH"),
  # Property characteristics: clip is the parcel key shared with OT
  columns = c("clip", "bedrooms", "bathrooms", "living_area"),  # TODO: confirm against your project's needs
  sample  = USE_SAMPLE
)

# Common arms-length cleaner
ot_clean <- filter_arms_length(ot, min_price = 5000)

# Join transactions to property characteristics via clip (CoreLogic's stable parcel identifier)
sample_panel <- ot_clean |>
  left_join(prop, by = "clip")

# Save derived data
write_parquet(sample_panel, fs::path(data_dir, "sample_panel.parquet"))
saveRDS(sample_panel, fs::path(out_dir, "sample_panel.rds"))

cat("Clean: ", nrow(sample_panel), " rows written.\n", sep = "")
