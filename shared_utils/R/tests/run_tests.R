#!/usr/bin/env Rscript
# Run all shared_utils/R smoke tests.
# Usage: Rscript shared_utils/R/tests/run_tests.R

suppressPackageStartupMessages({
  library(testthat)
  library(here)
})

test_root <- here("shared_utils", "R", "tests")
results <- test_dir(test_root, reporter = "summary", stop_on_failure = TRUE)
cat("\nAll shared_utils/R smoke tests passed.\n")
