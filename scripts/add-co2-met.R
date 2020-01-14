library(fs)
library(here)
library(magrittr, include.only = "%>%")
library(readr)
library(stringr)
library(dplyr, mask.ok = c("filter", "lag", "intersect", "setdiff",
                           "setequal", "union"))
library(hdf5r)
library(lubridate, exclude = c("here", "intersect", "setdiff", "union"),
        mask.ok = c("as.difftime", "date"))
library(purrr, exclude = "flatten_df")
library(tidyr)

requireNamespace("PEcAn.ED2", quietly = TRUE)

local_dir <- here("unsynced-data")
local_in_dir <- path(local_dir, "narr-ed") %>% dir_create()
local_out_dir <- path(local_dir, "narr-ed-co2") %>% dir_create()

# Copy all the files from in to out
.cp <- dir_copy(local_in_dir, local_out_dir, overwrite = TRUE)

# Read all the met files in as a tidy data.frame
met_ts <- tibble(
  full_path = dir_ls(local_out_dir, glob = "*.h5"),
  fname = path_file(full_path),
  date = str_remove(fname, "\\.h5$") %>% parse_date_time("ym")
) %>% arrange(date)

summary(met_ts)

law_dome_file <- here("extdata", "law2006.txt")
law_dome_raw <- readLines(law_dome_file)
ld_start <- 2464
ld_end <- 2715
stopifnot(
  grepl("3. CO2 by Age", law_dome_raw[ld_start - 4], fixed = TRUE),
  grepl("SampleType", law_dome_raw[ld_start]),
  grepl("^$", law_dome_raw[ld_end])
)
ld_sub <- read_table(
  law_dome_raw,
  skip = ld_start - 1,
  n_max = ld_end - ld_start - 1,
)

de08 <- ld_sub %>%
  filter(SampleType == "DE08") %>%
  arrange(CO2gasAge) %>%
  # Some years are duplicated -- average them out
  group_by(CO2gasAge) %>%
  summarize(co2 = mean(`CO2(ppm)`)) %>%
  ungroup()

# Convert DO08 years to dates. Assume January 1.
# TODO: Interpolate with more granulatity? Better assumption?
de08_date <- de08 %>%
  mutate(date = as.POSIXct(sprintf("%.0f-01-01 00:00:00", CO2gasAge))) %>%
  select(date, law_dome = co2) %>%
  # Remove duplicates -- take the earlier value
  group_by(date) %>%
  summarize(law_dome = mean(law_dome, na.rm = TRUE)) %>%
  ungroup()

mlo_file <- here("extdata", "co2_mm_mlo.txt")
mlo_cols <- c("year", "month", "decimal_year", "average", "interpolated", "trend", "no_days")
mlo_data <- read_table(mlo_file, skip = 72, col_names = mlo_cols) %>%
  mutate_at(vars(average, interpolated), ~if_else(. < 0, NA_real_, .)) %>%
  mutate(date = as.POSIXct(sprintf("%.0f-%.0f-15", year, month))) %>%
  select(date, mauna_loa = interpolated)

# Combine them both
co2_record <- de08_date %>%
  full_join(mlo_data, by = "date") %>%
  transmute(
    date = date,
    co2 = if_else(is.na(mauna_loa), law_dome, mauna_loa)
  )

if (interactive()) {
  plot(co2 ~ date, data = co2_record, type = "l")
}

start_date <- as.POSIXct("1890-01-01 00:00:00")
end_date <- as.POSIXct("2019-12-31 23:59:59")
co2_record_6hr <- tibble(
  date = seq(start_date, end_date, by = "6 hours"),
  co2 = approx(
    decimal_date(co2_record$date),
    co2_record$co2,
    decimal_date(date),
    # Extrapolate the ends with a constant value
    rule = 2
  )[["y"]]
)

if (interactive()) {
  plot(co2 ~ date, data = co2_record_6hr, type = "l")
}

# Nest by month, to match ED2 format
co2_record_nested_all <- co2_record_6hr %>%
  mutate(date_floor = floor_date(date, "month")) %>%
  group_by(date_floor) %>%
  nest()

stop(
  "TODO: This part is not done yet. ",
  "Need to fuse the other met data before adding the CO2."
)

co2_record_nested <- co2_record_nested_all %>%
  inner_join(met_ts, by = c("date_floor" = "date"))

add_co2 <- function(file, data) {
  co2 <- data[["co2"]]
  co2_array <- array(co2, c(length(co2), 1, 1))
  hf <- H5File$new(file)
  hf[["co2"]] <- co2_array
  hf$close_all()
  invisible(TRUE)
}

co2_wrote <- co2_record_nested %>%
  mutate(wrote = map2_lgl(full_path, data, possibly(add_co2, FALSE)))

filter(co2_wrote, !wrote)

# Write out the revised ED met header
emh <- PEcAn.ED2::read_ed_metheader(path(local_out_dir, "ED_MET_DRIVER_HEADER"),
                                    check = FALSE, check_files = FALSE)
emh[[1]][["path_prefix"]] <- "/data/dbfiles/CUSTOM_ED2_site_1-33/"
emh[[1]][["variables"]] <- emh[[1]][["variables"]] %>%
  filter(variable != "co2") %>%
  add_row(variable = "co2", flag = 1, update_frequency = 21600)
PEcAn.ED2::write_ed_metheader(emh, path(local_out_dir, "ED_MET_DRIVER_HEADER"))
