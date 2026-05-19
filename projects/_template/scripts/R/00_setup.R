#' Project setup — sourced at the top of every analysis script.
#'
#' This is the ONLY file in this project that touches paths.
#' All other scripts begin with:
#'   source(here::here("{{PROJECT_PATH}}/scripts/R/00_setup.R"))

suppressPackageStartupMessages({
  library(here)
  library(tidyverse)
  library(arrow)
  library(fs)
})

# ---- shared utilities ----
source(here("shared_utils", "R", "corelogic_loader.R"))
source(here("shared_utils", "R", "data_dictionary.R"))
source(here("shared_utils", "R", "filters.R"))
source(here("shared_utils", "R", "theme_paper.R"))
theme_set(theme_paper())

# ---- project-scoped paths ----
project_dir  <- here("{{PROJECT_PATH}}")
scripts_dir  <- path(project_dir, "scripts")
out_dir      <- path(scripts_dir, "R", "_outputs")
manuscript_dir <- path(project_dir, "manuscript")
tables_dir   <- path(manuscript_dir, "tables")
figures_dir  <- path(manuscript_dir, "figures")

# Project-specific derived data lives here (gitignored)
data_dir     <- here("data", "derived", "{{PROJECT_NUMBER}}_{{PROJECT_SLUG}}")
dir_create(data_dir)
dir_create(out_dir)

# ---- project-specific packages (add as needed) ----
# library(fixest)
# library(modelsummary)
# library(did)
