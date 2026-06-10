# build_fhfa_state_hpi.R
# Build a tidy annual state-level FHFA all-transactions HPI deflator table.
# Source: FHFA All-Transactions House Price Index, state level, NSA (quarterly),
#         aggregated to annual by averaging the four quarters per state-year.
# Raw file: data/external/_raw_hpi_at_state.csv
#   columns (no header): state_abbr, year, quarter, index_nsa
# Output: data/external/fhfa_state_hpi.parquet

suppressPackageStartupMessages({
  library(arrow)
  library(here)
})

raw_path <- here::here("data", "external", "_raw_hpi_at_state.csv")
out_path <- here::here("data", "external", "fhfa_state_hpi.parquet")

raw <- utils::read.csv(
  raw_path,
  header = FALSE,
  col.names = c("state_abbr", "year", "quarter", "hpi_q"),
  colClasses = c("character", "integer", "integer", "numeric"),
  stringsAsFactors = FALSE
)

stopifnot(ncol(raw) == 4L, nrow(raw) > 0L)

# Aggregate quarterly -> annual (mean of 4 quarters). Keep only complete years
# (all 4 quarters present) to avoid biased partial-year means.
agg <- aggregate(
  cbind(hpi = hpi_q, nq = 1) ~ state_abbr + year,
  data = raw,
  FUN = function(x) x  # placeholder; replaced below
)

# Base aggregate() can't do two FUNs cleanly; do it explicitly with tapply.
key <- interaction(raw$state_abbr, raw$year, drop = TRUE, sep = "")
hpi_mean <- tapply(raw$hpi_q, key, mean)
nq       <- tapply(raw$hpi_q, key, length)

split_key <- do.call(rbind, strsplit(names(hpi_mean), "", fixed = TRUE))
annual <- data.frame(
  state_abbr = split_key[, 1],
  year       = as.integer(split_key[, 2]),
  hpi        = as.numeric(round(hpi_mean, 4)),
  nq         = as.integer(nq),
  stringsAsFactors = FALSE
)

# Drop incomplete years (fewer than 4 quarters), then drop helper column.
annual <- annual[annual$nq == 4L, c("state_abbr", "year", "hpi")]

# State abbreviation -> 2-digit zero-padded FIPS.
fips_map <- c(
  AL = "01", AK = "02", AZ = "04", AR = "05", CA = "06", CO = "08", CT = "09",
  DE = "10", DC = "11", FL = "12", GA = "13", HI = "15", ID = "16", IL = "17",
  IN = "18", IA = "19", KS = "20", KY = "21", LA = "22", ME = "23", MD = "24",
  MA = "25", MI = "26", MN = "27", MS = "28", MO = "29", MT = "30", NE = "31",
  NV = "32", NH = "33", NJ = "34", NM = "35", NY = "36", NC = "37", ND = "38",
  OH = "39", OK = "40", OR = "41", PA = "42", RI = "44", SC = "45", SD = "46",
  TN = "47", TX = "48", UT = "49", VT = "50", VA = "51", WA = "53", WV = "54",
  WI = "55", WY = "56"
)

annual$state_fips <- fips_map[annual$state_abbr]

# Fail loudly if any abbreviation is unmapped.
if (anyNA(annual$state_fips)) {
  unmapped <- unique(annual$state_abbr[is.na(annual$state_fips)])
  stop("Unmapped state abbreviations: ", paste(unmapped, collapse = ", "))
}

# Final tidy column order + sort.
tidy <- annual[, c("state_abbr", "state_fips", "year", "hpi")]
tidy <- tidy[order(tidy$state_abbr, tidy$year), ]
rownames(tidy) <- NULL

arrow::write_parquet(tidy, out_path)

# --- Verification report -------------------------------------------------
cat("Wrote:", out_path, "\n")
cat("Rows:", nrow(tidy), "\n")
cat("Year range:", min(tidy$year), "-", max(tidy$year), "\n")
cat("Distinct states:", length(unique(tidy$state_abbr)), "\n")
cat("Sample CA (2008):\n"); print(tidy[tidy$state_abbr == "CA" & tidy$year == 2008, ])
cat("Sample OH (2008):\n"); print(tidy[tidy$state_abbr == "OH" & tidy$year == 2008, ])
cat("Sample CA (1990):\n"); print(tidy[tidy$state_abbr == "CA" & tidy$year == 1990, ])
cat("Head:\n"); print(utils::head(tidy, 3))
