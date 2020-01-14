library(fs)
library(dplyr)

ncep_dir <- path("unsynced-data", "meteorology", "CRUNCEP-ED2-CO2")
narr_dir <- path("unsynced-data", "meteorology", "NARR-ED2-CO2")

fparse_date <- function(x, tz = "UTC") {
  base <- fs::path_file(x) %>%
    stringr::str_remove("\\.h5$")
  lubridate::parse_date_time(base, "ym", tz = tz)
}

ncep_df <- tibble(
  ncep_file = dir_ls(ncep_dir, glob = "*.h5"),
  date = fparse_date(ncep_file)
)

narr_df <- tibble(
  narr_file = dir_ls(narr_dir, glob = "*.h5"),
  date = fparse_date(narr_file)
)

both_df <- full_join(ncep_df, narr_df, by = "date") %>%
  select(date, everything()) %>%
  arrange(date)

# Prefer NARR; fall back to CRUNCEP
hybrid_dir <- path("unsynced-data", "meteorology", "hybrid-ED2") %>%
  dir_create()
selected <- both_df %>%
  transmute(
    date = date,
    source_file = if_else(is.na(narr_file), ncep_file, narr_file),
    target_file = path(
      hybrid_dir,
      paste(path_file(path_dir(source_file)), path_file(source_file),
            sep = "."))
  )

with(selected, file_copy(source_file, target_file))

# Create ED MET DRIVER HEADER
ed_met_header <- c(
  "'ED hybrid meteorology: CRUNCEP + NARR'",
  "2",
  # CRUNCEP met -- 6 hourly
  "unsynced-data/meteorology/hybrid-ED2/CRUNCEP-ED2-CO2.",
  "1 1 1 1 -84.6975 45.5625",
  "13",
  "dlwrf hgt nbdsf nddsf prate pres sh tmp ugrd vbdsf vddsf vgrd co2",
  "21600 21600 21600 21600 21600 21600 21600 21600 21600 21600 21600 21600 21600", #nolint
  "1 1 1 1 1 1 1 1 1 1 1 1 1",
  # NARR met -- 3 hourly
  "unsynced-data/meteorology/hybrid-ED2/NARR-ED2-CO2.",
  "1 1 1 1 -84.6975 45.5625",
  "13",
  "dlwrf hgt nbdsf nddsf prate pres sh tmp ugrd vbdsf vddsf vgrd co2",
  "10800 10800 10800 10800 10800 10800 10800 10800 10800 10800 10800 10800 10800", #nolint
  "1 1 1 1 1 1 1 1 1 1 1 1 1"
)
writeLines(ed_met_header, path(hybrid_dir, "ED_MET_DRIVER_HEADER"))
