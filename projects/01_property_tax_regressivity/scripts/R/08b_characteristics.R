#' 08b: Structural characteristics per parcel, for the hedonic instrument.
#'
#' Pulls the hedonic predictors (living area, beds, baths, year built, lot,
#' stories) from the prop store, one row per clip. Used in 08_iv_division_bias.R
#' to build a characteristics-only predicted value that instruments the focal
#' sale price (an instrument orthogonal to the focal sale's transitory noise).
#'
#' Output: characteristics.parquet (clip + hedonic columns)

source(here::here("projects/01_property_tax_regressivity/scripts/R/00_setup.R"))

CHAR_COLS <- c(
  "clip",
  living  = "total_living_area_square_feet_all_buildings",
  beds    = "total_number_of_bedrooms_all_buildings",
  baths   = "total_number_of_bathrooms_all_buildings",
  yrbuilt = "year_built",
  lot     = "total_land_square_footage",
  stories = "total_number_of_stories"
)

prop_root  <- here::here("data/corelogic_extracts/by_state/prop")
state_dirs <- fs::dir_ls(prop_root, type = "directory")
log_msg("Reading characteristics from ", length(state_dirs), " prop partitions...")

num_id <- function(x) suppressWarnings(as.numeric(x))

clist <- vector("list", length(state_dirs))
for (i in seq_along(state_dirs)) {
  part <- fs::path(state_dirs[i], "part.parquet")
  if (!fs::file_exists(part)) next
  df <- tryCatch(
    arrow::read_parquet(part, col_select = dplyr::any_of(unname(CHAR_COLS))),
    error = function(e) { log_msg("  ERR ", fs::path_file(state_dirs[i]), ": ",
                                  conditionMessage(e)); NULL })
  if (is.null(df) || !("clip" %in% names(df))) next
  # rename to short names; coerce all to character/numeric for safe binding
  for (nm in names(CHAR_COLS)[-1]) {
    src <- CHAR_COLS[[nm]]
    df[[nm]] <- if (src %in% names(df)) num_id(df[[src]]) else NA_real_
  }
  out <- data.frame(clip = as.character(df[["clip"]]))
  for (nm in names(CHAR_COLS)[-1]) out[[nm]] <- df[[nm]]
  clist[[i]] <- out
  if (i %% 10L == 0L) log_msg("  ", i, "/", length(state_dirs), " states")
}
ch <- dplyr::bind_rows(clist)
log_msg("Characteristics rows (pre-dedup): ", format(nrow(ch), big.mark = ","))

# normalize clip and keep one row per clip, preferring the most complete record
norm_id <- function(x) sub("\\.0+$", "", trimws(as.character(x)))
ch <- ch |>
  mutate(clip_chr = norm_id(clip),
         n_nonNA  = rowSums(!is.na(across(c(living, beds, baths, yrbuilt, lot, stories))))) |>
  filter(!is.na(clip_chr), clip_chr != "") |>
  arrange(clip_chr, desc(n_nonNA)) |>
  distinct(clip_chr, .keep_all = TRUE) |>
  select(clip_chr, living, beds, baths, yrbuilt, lot, stories)
log_msg("Characteristics rows (one per clip): ", format(nrow(ch), big.mark = ","))
log_msg("Non-NA rates: living ", round(100*mean(!is.na(ch$living)),1),
        "% | beds ", round(100*mean(!is.na(ch$beds)),1),
        "% | yrbuilt ", round(100*mean(!is.na(ch$yrbuilt)),1), "%")

write_parquet(ch, path(data_dir, "characteristics.parquet"))
log_msg("DONE — characteristics.parquet cached.")
