suppressPackageStartupMessages(library(tidyverse))
st <- read_csv("projects/03_family_homes/scripts/R/_outputs/tables/fact_state_class_2017_2023.csv",
               show_col_types = FALSE) |>
  filter(!state %in% c("GU","PR","VI","AS","MP","AE","AP","AA","FM","MH","PW")) |>
  mutate(ratio = fam_broad / market) |>
  arrange(desc(ratio))
print(head(st |> select(state, ratio), 6))
print(tail(st |> select(state, ratio), 3))
pooled <- sum(st$fam_broad) / sum(st$market)
cat("pooled national:", round(pooled, 4), "\n")
cat("CA trust share of national:",
    round(st$trust[st$state == "CA"] / sum(st$trust), 4), "\n")
perm <- read_csv("projects/03_family_homes/scripts/R/_outputs/tables/ref_perm_volume_all.csv",
                 show_col_types = FALSE) |> arrange(coef_fam)
print(head(perm, 6))
