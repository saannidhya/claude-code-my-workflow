#' Project setup - sourced at the top of every analysis script.

suppressPackageStartupMessages({
  library(here)
  library(tidyverse)
  library(arrow)
  library(duckdb)
  library(DBI)
  library(fs)
  library(glue)
  library(scales)
})

source(here("shared_utils", "R", "corelogic_loader.R"))
source(here("shared_utils", "R", "filters.R"))
source(here("shared_utils", "R", "theme_paper.R"))
theme_set(theme_paper())

project_dir    <- here("projects", "02_cash_buyer_premium")
scripts_dir    <- path(project_dir, "scripts")
r_dir          <- path(scripts_dir, "R")
out_dir        <- path(r_dir, "_outputs")
tables_dir     <- path(out_dir, "tables")
figures_dir    <- path(out_dir, "figures")
logs_dir       <- path(out_dir, "logs")
external_dir   <- here("data", "external", "02_cash_buyer_premium")
data_dir       <- here("data", "derived", "02_cash_buyer_premium")

dir_create(out_dir)
dir_create(tables_dir)
dir_create(figures_dir)
dir_create(logs_dir)
dir_create(external_dir)
dir_create(data_dir)

ot_parquet_glob <- function() {
  root <- normalizePath(here("data", "corelogic_extracts", "by_state", "ot"), winslash = "/", mustWork = TRUE)
  gsub("\\\\", "/", file.path(root, "state=*", "year=*", "*.parquet"))
}

prop_parquet_glob <- function() {
  root <- normalizePath(here("data", "corelogic_extracts", "by_state", "prop"), winslash = "/", mustWork = TRUE)
  gsub("\\\\", "/", file.path(root, "state=*", "*.parquet"))
}

sql_quote_path <- function(x) {
  gsub("'", "''", x, fixed = TRUE)
}

open_corelogic_duckdb <- function(memory_limit = "12GB", threads = max(1L, parallel::detectCores() - 1L)) {
  con <- dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  dbExecute(con, glue("PRAGMA memory_limit='{memory_limit}'"))
  dbExecute(con, glue("PRAGMA threads={threads}"))
  con
}

write_csv_strict <- function(x, file) {
  dir_create(path_dir(file))
  readr::write_csv(x, file, na = "")
  message("Wrote: ", file)
}

fred_mortgage30us_url <- "https://fred.stlouisfed.org/graph/fredgraph.csv?id=MORTGAGE30US"
fred_mortgage30us_csv <- path(external_dir, "fred_mortgage30us.csv")

modern_start_year <- 2007L
modern_end_year   <- 2024L
post_rate_shock_year <- 2022L
