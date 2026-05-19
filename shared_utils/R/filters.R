#' Common cleaners for CoreLogic data

suppressPackageStartupMessages({
  library(dplyr)
})

#' Valid US state / territory / APO codes
VALID_STATE_CODES <- c(
  # 50 states
  "AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA",
  "KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ",
  "NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT",
  "VA","WA","WV","WI","WY",
  # DC + US territories
  "DC", "PR", "GU", "AS", "VI", "MP", "FM", "MH", "PW",
  # Military APO codes
  "AA", "AE", "AP"
)

#' Check if a state code is valid
#' @param code Character vector. State / territory / APO codes.
#' @return Logical vector.
is_valid_state_code <- function(code) {
  if (length(code) == 0) return(logical(0))
  vapply(code, function(x) {
    if (is.na(x)) return(FALSE)
    if (!is.character(x)) return(FALSE)
    if (nchar(x) != 2) return(FALSE)
    toupper(x) %in% VALID_STATE_CODES
  }, logical(1), USE.NAMES = FALSE)
}

#' Filter to arms-length transactions
#'
#' Drops intra-family transfers, foreclosures (by default), and
#' zero/nominal-price sales. Tunable thresholds.
#'
#' @param df Data frame with CoreLogic OT columns
#' @param min_price Minimum sale price to keep (default 1000)
#' @param allow_foreclosure If TRUE, keep foreclosure transactions
#' @return Filtered tibble
filter_arms_length <- function(df, min_price = 1000, allow_foreclosure = FALSE) {
  out <- df

  # Drop intra-family if column exists
  if ("INTRA_FAMILY_FLAG" %in% names(out)) {
    out <- out |> filter(is.na(INTRA_FAMILY_FLAG) | INTRA_FAMILY_FLAG != "Y")
  }

  # Drop zero/nominal-price
  if ("SALE_AMOUNT" %in% names(out)) {
    out <- out |> filter(!is.na(SALE_AMOUNT), SALE_AMOUNT >= min_price)
  }

  # Drop foreclosures unless explicitly allowed
  if (!allow_foreclosure && "TRANSACTION_TYPE" %in% names(out)) {
    out <- out |> filter(is.na(TRANSACTION_TYPE) | TRANSACTION_TYPE != "FORECLOSURE")
  }

  out
}
