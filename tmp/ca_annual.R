suppressPackageStartupMessages(library(tidyverse))
m <- read_csv("projects/03_family_homes/scripts/R/_outputs/tables/prop19_monthly_series.csv",
              show_col_types = FALSE)
ca <- m |> filter(state == "CA") |> group_by(sale_year) |>
  summarise(fam = sum(n_fam), trust = sum(n_trust), market = sum(n_market))
print(ca)
cat("CA fam mean 2018-2019:", mean(ca$fam[ca$sale_year %in% 2018:2019]), "\n")
cat("CA fam mean 2022-2023:", mean(ca$fam[ca$sale_year %in% 2022:2023]), "\n")
us <- m |> group_by(sale_year) |> summarise(fam = sum(n_fam))
print(us)
