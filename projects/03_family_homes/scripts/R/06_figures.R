# ============================================================
# 06: Manuscript figures
# Author: Saani Rawat
# Purpose: Figures for paper.tex, built ONLY from _outputs/ artifacts
#          produced by 02-04 (no direct CoreLogic access here).
# Inputs:  _outputs/tables/*.csv, _outputs/*.rds
# Outputs: manuscript/figures/F1_volumes.pdf
#          manuscript/figures/F2_state_ratio.pdf
#          manuscript/figures/F3_km_curves.pdf
#          manuscript/figures/F4_prop19_bunching.pdf
#          manuscript/figures/F5_sold24_cohorts.pdf
# ============================================================

source(here::here("projects/03_family_homes/scripts/R/00_setup.R"))

set.seed(20260609)

save_fig <- function(p, name, width = 9, height = 5) {
  ggsave(path(figures_dir, paste0(name, ".pdf")), p,
         width = width, height = height, bg = "transparent")
  ggsave(path(figures_dir, paste0(name, ".png")), p,
         width = width, height = height, bg = "transparent", dpi = 300)
  message("Saved figure: ", name)
}

# ---- F1: national volumes ------------------------------------------------
headline <- read_csv(path(tables_out_dir, "fact_headline_ratios.csv"),
                     show_col_types = FALSE)
f1_dat <- headline |>
  select(sale_year, `Family transfer (broad)` = fam_broad,
         `Family transfer (same-surname)` = fam_conservative,
         `Trust self-transfer` = trust,
         `Market sale` = market) |>
  pivot_longer(-sale_year, names_to = "series", values_to = "n")

f1 <- ggplot(f1_dat, aes(sale_year, n / 1e6, color = series)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6) +
  scale_color_paper() +
  scale_x_continuous(breaks = seq(2007, 2023, 2)) +
  labs(x = NULL, y = "Residential deed events (millions/year)", color = NULL)
save_fig(f1, "F1_volumes")

# ---- F2: state family:market ratio ---------------------------------------
st <- read_csv(path(tables_out_dir, "fact_state_class_2017_2023.csv"),
               show_col_types = FALSE) |>
  filter(!state %in% c("GU", "PR", "VI", "AS", "MP", "AE", "AP", "AA", "FM", "MH", "PW")) |>
  mutate(ratio = fam_broad / market) |>
  arrange(desc(ratio))

f2 <- ggplot(st, aes(x = reorder(state, ratio), y = ratio)) +
  geom_col(fill = palette_paper()[1], width = 0.75) +
  coord_flip() +
  labs(x = NULL, y = "Family transfers per market sale, 2017–2023") +
  theme(axis.text.y = element_text(size = 6.5))
save_fig(f2, "F2_state_ratio", width = 7, height = 8)

# ---- F3: KM survival curves ----------------------------------------------
km <- readRDS(path(out_dir, "hazard_km_curves.rds"))
label_map <- c(
  family_person = "Family transfer (same surname)",
  family_other  = "Family transfer (other)",
  family_trust  = "Trust self-transfer",
  market_sale   = "Market purchase"
)
f3_dat <- km |>
  filter(class %in% names(label_map)) |>  # family_estate excluded: n = 915
  mutate(lab = label_map[class])

f3 <- ggplot(f3_dat, aes(t / 12, surv, color = lab)) +
  geom_line(linewidth = 0.9) +
  scale_color_paper() +
  scale_y_continuous(limits = c(0.4, 1), labels = percent_format()) +
  scale_x_continuous(breaks = 0:10) +
  guides(color = guide_legend(nrow = 2)) +
  labs(x = "Years since transfer event (2008–2018 cohorts)",
       y = "Share not yet sold on the open market", color = NULL)
save_fig(f3, "F3_km_curves")

# ---- F4: Prop 19 bunching ------------------------------------------------
cf <- read_csv(path(tables_out_dir, "prop19_ca_counterfactual_monthly.csv"),
               show_col_types = FALSE) |>
  mutate(date = as.Date(paste0(sale_year, "-", sale_month, "-01")))

f4 <- ggplot(cf, aes(date)) +
  geom_line(aes(y = ca_actual / 1000, color = "California, actual"), linewidth = 0.9) +
  geom_line(aes(y = ca_cf / 1000, color = "Counterfactual (2019 CA × rest-of-US growth)"),
            linewidth = 0.9, linetype = "22") +
  geom_vline(xintercept = as.Date(c("2020-11-03", "2021-02-16")),
             linetype = "dotted", color = "grey30") +
  annotate("text", x = as.Date("2020-10-20"), y = max(cf$ca_actual) / 1000 * 0.97,
           label = "passed", hjust = 1, size = 3, color = "grey30") +
  annotate("text", x = as.Date("2021-03-01"), y = max(cf$ca_actual) / 1000 * 0.97,
           label = "effective", hjust = 0, size = 3, color = "grey30") +
  scale_color_manual(values = palette_paper()[c(2, 1)]) +
  labs(x = NULL, y = "CA family transfers (thousands/month)", color = NULL)
save_fig(f4, "F4_prop19_bunching")

# ---- F5: sold-within-24m by cohort ---------------------------------------
cells <- read_csv(path(tables_out_dir, "prop19_cohort_cells.csv"),
                  show_col_types = FALSE)
f5_dat <- cells |>
  filter(grp == "fam") |>
  mutate(group = if_else(ca == 1, "California", "Rest of US"),
         date = as.Date(paste0(ym %/% 100, "-", ym %% 100, "-01"))) |>
  group_by(group, date, post) |>
  summarise(sold24 = weighted.mean(sold24, n), .groups = "drop")

f5 <- ggplot(f5_dat, aes(date, sold24, color = group)) +
  geom_point(size = 1.4, alpha = 0.85) +
  geom_line(linewidth = 0.5, alpha = 0.6) +
  scale_color_manual(values = palette_paper()[c(2, 1)]) +
  scale_y_continuous(labels = percent_format()) +
  labs(x = "Family-transfer cohort month",
       y = "Sold on open market within 24 months", color = NULL)
save_fig(f5, "F5_sold24_cohorts")

message("Finished 06_figures at ", Sys.time())
