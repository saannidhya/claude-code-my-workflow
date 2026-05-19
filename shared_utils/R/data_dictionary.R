#' CoreLogic Data Dictionary parser
#'
#' Parses a CoreLogic dd.txt file into a tibble for use by the loader and by
#' analysis code (`describe_col()`).
#'
#' Expected dd.txt format: tab-separated with header row containing
#' FIELD, TYPE, START, END, DESCRIPTION columns. Tolerant of variations
#' in column order; matches by header name (case-insensitive).

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tibble)
})

#' Parse a CoreLogic data dictionary file
#'
#' @param dd_path Path to dd.txt (tab-separated)
#' @return Tibble with columns: name, type, start_pos, end_pos, description
#' @export
parse_data_dictionary <- function(dd_path) {
  stopifnot(file.exists(dd_path))
  raw <- read_tsv(dd_path, show_col_types = FALSE, progress = FALSE)
  # Normalize column names: lowercase, map to standard names
  names(raw) <- tolower(names(raw))
  required <- c("field", "type", "start", "end", "description")
  missing_cols <- setdiff(required, names(raw))
  if (length(missing_cols) > 0) {
    stop("dd.txt missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  tibble(
    name = raw$field,
    type = raw$type,
    start_pos = as.integer(raw$start),
    end_pos = as.integer(raw$end),
    description = raw$description
  )
}

#' Look up the description for a CoreLogic column
#'
#' @param col_name Column name (matched against dd$name)
#' @param dd Data dictionary tibble from `parse_data_dictionary()`
#' @return Description string
#' @export
describe_col <- function(col_name, dd) {
  row <- dd[dd$name == col_name, ]
  if (nrow(row) == 0) {
    stop("Column '", col_name, "' not found in data dictionary")
  }
  row$description[1]
}
