library(testthat)

source(here::here("projects/02_cash_buyer_premium/scripts/R/repeat_sale_helpers.R"))

test_that("classify_purchase_type applies mutually exclusive cash priority", {
  result <- classify_purchase_type(
    cash = c(1, 1, 1, 1, 0, 1, NA),
    mortgage = c(0, 0, 0, 0, 1, 1, 0),
    investor = c(0, 1, 0, 1, 0, 0, 0),
    corporate_buyer = c(0, 0, 1, 1, 0, 0, 0),
    foreclosure_reo = c(0, 0, 0, 1, 0, 0, 0),
    foreclosure_reo_sale = c(0, 0, 0, 0, 0, 0, 0)
  )

  expect_equal(
    result,
    c(
      "ordinary_cash",
      "investor_cash",
      "corporate_cash",
      "distress_cash",
      "mortgage",
      "ordinary_cash",
      "other_or_unknown"
    )
  )
})

test_that("annualized_log_return requires positive holding period", {
  result <- annualized_log_return(
    log_buy_price = log(c(100, 100, 100)),
    log_sell_price = log(c(121, 110, 90)),
    holding_years = c(2, 0, NA)
  )

  expect_equal(result[1], log(121 / 100) / 2, tolerance = 1e-12)
  expect_true(is.na(result[2]))
  expect_true(is.na(result[3]))
})

test_that("hpi_adjusted_annualized_log_return subtracts local HPI growth", {
  result <- hpi_adjusted_annualized_log_return(
    log_buy_price = log(c(100, 100, 100, 100)),
    log_sell_price = log(c(150, 150, 150, 150)),
    purchase_hpi = c(100, 100, 0, 100),
    resale_hpi = c(125, 100, 125, NA),
    holding_years = c(2, 2, 2, 2)
  )

  expect_equal(result[1], (log(150 / 100) - log(125 / 100)) / 2, tolerance = 1e-12)
  expect_equal(result[2], log(150 / 100) / 2, tolerance = 1e-12)
  expect_true(is.na(result[3]))
  expect_true(is.na(result[4]))
})

test_that("repeat_sale_hold_bin applies publication holding-period bins", {
  result <- repeat_sale_hold_bin(c(0.49, 0.5, 0.99, 1, 1.99, 2, 3.99, 4, 6, 6.01, NA))

  expect_equal(
    as.character(result),
    c(
      NA,
      "0.5-1 years",
      "0.5-1 years",
      "1-2 years",
      "1-2 years",
      "2-4 years",
      "2-4 years",
      "4-6 years",
      "4-6 years",
      NA,
      NA
    )
  )
})

test_that("winsorize_vec caps finite tails and preserves missing values", {
  result <- winsorize_vec(c(NA, -10, 0, 1, 100), probs = c(0.25, 0.75))

  expect_true(is.na(result[1]))
  expect_equal(result[2], -2.5)
  expect_equal(result[5], 25.75)
})
