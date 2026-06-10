# Probe: feasibility of intergenerational / non-market transfer research question
# Sandbox exploration — 2026-06-09
# Q1: How well-populated is interfamily_related_indicator (by year)?
# Q2: What are the values of primary_category_code / deed_category_type_code?
# Q3: Sale amounts for interfamily vs arm's-length?

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})
source(here::here("shared_utils", "R", "corelogic_loader.R"))

ot <- load_corelogic_ot(sample = TRUE)

cat("=== N rows in sample:", nrow(ot), "===\n\n")

cat("=== interfamily_related_indicator values ===\n")
print(table(ot$interfamily_related_indicator, useNA = "ifany"))

cat("\n=== primary_category_code values ===\n")
print(table(ot$primary_category_code, useNA = "ifany"))

cat("\n=== deed_category_type_code values (top 25) ===\n")
print(sort(table(ot$deed_category_type_code, useNA = "ifany"), decreasing = TRUE)[1:25])

cat("\n=== sale_type_code values ===\n")
print(table(ot$sale_type_code, useNA = "ifany"))

cat("\n=== Year coverage of sample (deciles of year) ===\n")
print(quantile(ot$year, probs = seq(0, 1, 0.1), na.rm = TRUE))

cat("\n=== Interfamily flag by year band ===\n")
ot |>
  mutate(band = cut(year, breaks = c(1900, 1980, 1990, 2000, 2010, 2015, 2020, 2025))) |>
  group_by(band) |>
  summarise(
    n = n(),
    fam_y = sum(interfamily_related_indicator == "Y", na.rm = TRUE),
    fam_na = sum(is.na(interfamily_related_indicator)),
    .groups = "drop"
  ) |>
  print(n = 30)

cat("\n=== Sale amount by interfamily flag (recent years 2010+) ===\n")
ot |>
  filter(year >= 2010) |>
  mutate(fam = ifelse(is.na(interfamily_related_indicator), "NA",
                      interfamily_related_indicator)) |>
  group_by(fam) |>
  summarise(
    n = n(),
    p_zero = mean(sale_amount == 0 | is.na(sale_amount)),
    med_amt = median(sale_amount, na.rm = TRUE),
    .groups = "drop"
  ) |>
  print()

cat("\n=== Crosstab: primary_category_code x interfamily (2010+) ===\n")
ot |>
  filter(year >= 2010) |>
  count(primary_category_code, interfamily_related_indicator) |>
  print(n = 40)

cat("\n=== Other flags coverage 2015+ ===\n")
ot |>
  filter(year >= 2015) |>
  summarise(
    n = n(),
    cash_y = mean(cash_purchase_indicator == "Y", na.rm = TRUE),
    inv_y = mean(investor_purchase_indicator == "Y", na.rm = TRUE),
    resale_y = mean(resale_indicator == "Y", na.rm = TRUE),
    newcon_y = mean(new_construction_indicator == "Y", na.rm = TRUE),
    resid_y = mean(residential_indicator == "Y", na.rm = TRUE),
    corp_b1 = mean(buyer_1_corporate_indicator == "Y", na.rm = TRUE)
  ) |>
  print(width = Inf)
