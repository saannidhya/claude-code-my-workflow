library(testthat)
library(here)
library(dplyr)
library(arrow)
library(fs)

source(here("shared_utils/R/corelogic_loader.R"))

# Build a synthetic partitioned parquet store for testing
setup_mini_store <- function() {
  tmp <- tempfile("mini_corelogic_")
  dir_create(path(tmp, "by_state/ot/state=OH/year=2020"))
  dir_create(path(tmp, "by_state/ot/state=OH/year=2021"))
  dir_create(path(tmp, "by_state/ot/state=CA/year=2020"))
  dir_create(path(tmp, "by_state/prop/state=OH"))

  ot_oh_2020 <- tibble(APN = c("A1","A2"), SALE_AMOUNT = c(100000, 200000))
  ot_oh_2021 <- tibble(APN = c("A3"),       SALE_AMOUNT = c(300000))
  ot_ca_2020 <- tibble(APN = c("B1","B2"), SALE_AMOUNT = c(500000, 600000))
  prop_oh    <- tibble(APN = c("A1","A2","A3"), BEDROOMS = c(3L,4L,2L))

  write_parquet(ot_oh_2020, path(tmp, "by_state/ot/state=OH/year=2020/part.parquet"))
  write_parquet(ot_oh_2021, path(tmp, "by_state/ot/state=OH/year=2021/part.parquet"))
  write_parquet(ot_ca_2020, path(tmp, "by_state/ot/state=CA/year=2020/part.parquet"))
  write_parquet(prop_oh,    path(tmp, "by_state/prop/state=OH/part.parquet"))

  tmp
}

test_that("load_corelogic_ot returns full dataset when no filters", {
  store <- setup_mini_store()
  result <- load_corelogic_ot(parquet_root = store)
  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 5)  # 2 + 1 + 2
})

test_that("load_corelogic_ot filters by state", {
  store <- setup_mini_store()
  result <- load_corelogic_ot(states = "OH", parquet_root = store)
  expect_equal(nrow(result), 3)
  expect_true(all(result$state == "OH"))
})

test_that("load_corelogic_ot filters by year", {
  store <- setup_mini_store()
  result <- load_corelogic_ot(years = 2020, parquet_root = store)
  expect_equal(nrow(result), 4)
  expect_true(all(result$year == 2020))
})

test_that("load_corelogic_ot filters by both state and year", {
  store <- setup_mini_store()
  result <- load_corelogic_ot(states = "OH", years = 2020, parquet_root = store)
  expect_equal(nrow(result), 2)
  expect_true(all(result$state == "OH" & result$year == 2020))
})

test_that("load_corelogic_ot selects requested columns only", {
  store <- setup_mini_store()
  result <- load_corelogic_ot(columns = c("APN", "SALE_AMOUNT"), parquet_root = store)
  expect_true(all(c("APN", "SALE_AMOUNT") %in% names(result)))
})

test_that("load_corelogic_prop returns property data", {
  store <- setup_mini_store()
  result <- load_corelogic_prop(states = "OH", parquet_root = store)
  expect_equal(nrow(result), 3)
})
