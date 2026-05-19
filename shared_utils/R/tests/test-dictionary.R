library(testthat)
library(here)

source(here("shared_utils/R/data_dictionary.R"))

test_that("parse_data_dictionary returns a tibble with required columns", {
  dd_path <- tempfile(fileext = ".txt")
  writeLines(c(
    "FIELD\tTYPE\tSTART\tEND\tDESCRIPTION",
    "FIPS_CODE\tCHAR\t1\t5\tFIPS state-county code",
    "APN\tCHAR\t6\t30\tAssessor parcel number",
    "SALE_AMOUNT\tNUM\t31\t40\tSale price in dollars"
  ), dd_path)

  result <- parse_data_dictionary(dd_path)

  expect_s3_class(result, "tbl_df")
  expect_named(result, c("name", "type", "start_pos", "end_pos", "description"))
  expect_equal(nrow(result), 3)
  expect_equal(result$name[1], "FIPS_CODE")
  expect_equal(result$type[3], "NUM")
})

test_that("describe_col returns the description for a known column", {
  dd_path <- tempfile(fileext = ".txt")
  writeLines(c(
    "FIELD\tTYPE\tSTART\tEND\tDESCRIPTION",
    "APN\tCHAR\t6\t30\tAssessor parcel number"
  ), dd_path)
  dd <- parse_data_dictionary(dd_path)

  expect_equal(describe_col("APN", dd), "Assessor parcel number")
})

test_that("describe_col errors on unknown column", {
  dd_path <- tempfile(fileext = ".txt")
  writeLines(c(
    "FIELD\tTYPE\tSTART\tEND\tDESCRIPTION",
    "APN\tCHAR\t6\t30\tAssessor parcel number"
  ), dd_path)
  dd <- parse_data_dictionary(dd_path)

  expect_error(describe_col("UNKNOWN_COL", dd), "not found")
})
