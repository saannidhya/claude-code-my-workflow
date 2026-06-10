#' Helper functions for repeat-sale intermediation analyses.

truthy_one <- function(x) {
  !is.na(x) & x == 1
}

#' Classify the purchase-side buyer type into mutually exclusive categories.
#'
#' Priority is distress cash > investor cash > corporate cash > ordinary cash >
#' mortgage > other/unknown. The priority keeps repeat-sale return tables
#' mutually exclusive even when CoreLogic flags overlap.
classify_purchase_type <- function(cash, mortgage, investor, corporate_buyer,
                                   foreclosure_reo, foreclosure_reo_sale) {
  cash <- truthy_one(cash)
  mortgage <- truthy_one(mortgage)
  investor <- truthy_one(investor)
  corporate_buyer <- truthy_one(corporate_buyer)
  distress <- truthy_one(foreclosure_reo) | truthy_one(foreclosure_reo_sale)

  dplyr::case_when(
    cash & distress ~ "distress_cash",
    cash & investor ~ "investor_cash",
    cash & corporate_buyer ~ "corporate_cash",
    cash ~ "ordinary_cash",
    !cash & mortgage ~ "mortgage",
    TRUE ~ "other_or_unknown"
  )
}

#' Annualized log return from a purchase-resale pair.
annualized_log_return <- function(log_buy_price, log_sell_price, holding_years) {
  out <- (log_sell_price - log_buy_price) / holding_years
  out[is.na(holding_years) | holding_years <= 0] <- NA_real_
  out
}

#' Annualized repeat-sale return net of local HPI growth.
hpi_adjusted_annualized_log_return <- function(log_buy_price, log_sell_price,
                                               purchase_hpi, resale_hpi,
                                               holding_years) {
  raw_return <- annualized_log_return(log_buy_price, log_sell_price, holding_years)
  hpi_growth <- annualized_log_return(log(purchase_hpi), log(resale_hpi), holding_years)
  out <- raw_return - hpi_growth
  invalid_hpi <- is.na(purchase_hpi) | is.na(resale_hpi) | purchase_hpi <= 0 | resale_hpi <= 0
  out[invalid_hpi] <- NA_real_
  out
}

#' Holding-period bins used in repeat-sale robustness tables.
repeat_sale_hold_bin <- function(holding_years) {
  out <- cut(
    holding_years,
    breaks = c(0.5, 1, 2, 4, 6),
    labels = c("0.5-1 years", "1-2 years", "2-4 years", "4-6 years"),
    right = FALSE,
    include.lowest = TRUE
  )
  out[holding_years == 6] <- "4-6 years"
  out
}

#' Winsorize finite vector values at requested quantiles.
winsorize_vec <- function(x, probs = c(0.01, 0.99)) {
  stopifnot(length(probs) == 2, probs[1] >= 0, probs[2] <= 1, probs[1] < probs[2])
  finite <- is.finite(x)
  if (!any(finite)) return(x)
  cuts <- stats::quantile(x[finite], probs = probs, na.rm = TRUE, names = FALSE, type = 7)
  out <- x
  out[finite] <- pmin(pmax(out[finite], cuts[1]), cuts[2])
  out
}
