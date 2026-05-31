#' 04: Generate manuscript figures.

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

panel <- readRDS(fs::path(out_dir, "sample_panel.rds"))

# Example: sale price over time (snake_case CoreLogic schema)
p_prices <- panel |>
  # year was already derived in 01_clean.R; this assumes panel has it
  group_by(year) |>
  summarize(median_price = median(sale_amount, na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(year, median_price)) +
  geom_line(linewidth = 0.8) +
  geom_point() +
  labs(
    title    = "Median sale price by year",
    subtitle = "Property Tax Assessment Regressivity — preliminary",
    x        = "Year",
    y        = "Median sale price (USD)",
    caption  = "Source: CoreLogic. Sample placeholder."
  )

ggsave(
  fs::path(figures_dir, "F1_median_price_trend.pdf"),
  p_prices, width = 6, height = 4, device = cairo_pdf
)

cat("Figures written to: ", figures_dir, "\n", sep = "")
