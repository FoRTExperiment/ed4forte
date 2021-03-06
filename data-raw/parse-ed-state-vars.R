library(stringr)
library(dplyr)
library(tidyr)

stopifnot(requireNamespace("here", quietly = TRUE))
source(here::here("data-raw", "helpers.R"))

# Path to ED2 source file
# By default, pulls from GitHub -- master branch
ed2_base_path <- "https://raw.githubusercontent.com/EDmodel/ED2/master/"
state_vars_file <- file.path(ed2_base_path, "ED", "src", "memory", "ed_state_vars.F90")
state_vars_string <- readLines(state_vars_file)
state_vars_raw <- trimws(state_vars_string) %>%
  grep("^!", ., invert = TRUE, value = TRUE) %>%
  .[. != ""]

sv2 <- read_raw_fortran(state_vars_raw)

vtable_get_args <- function(x) {
  x %>%
    str_remove("\\) *$") %>%
    read.csv(text = ., row.names = NULL, header = FALSE, quote = "\"'",
             stringsAsFactors = FALSE) %>%
    as_tibble() %>%
    mutate_all(trimws)
}

vtable_sca_vals <- grep("call vtable_edio_[ir]_sca", sv2, value = TRUE)
vtable_sca_parse <- vtable_sca_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2)
vtable_sca_call <- vtable_sca_parse[, 1]
vtable_sca_args <- vtable_get_args(vtable_sca_parse[, 2]) %>%
  filter(V4 == 0) %>%
  select(code_variable = V1, info_string = V9)

vtable_vals <- grep("call vtable_edio_[ir] *\\(", sv2, value = TRUE)
vtable_parse <- vtable_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2)
vtable_call <- vtable_parse[, 1]
vtable_args <- vtable_get_args(vtable_parse[, 2]) %>%
  filter(!grepl("SLZ|HGT_CLASS", V10)) %>%
  select(code_variable = V2, info_string = V10, glob_id = V6)

meta_vals <- grep("call metadata_edio", sv2, value = TRUE)

meta_args_raw <- meta_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2) %>%
  .[, 2] %>%
  str_remove("\\) *$")

meta_args <- meta_args_raw %>%
  paste(collapse = "\n") %>%
  read.csv(text = ., row.names = NULL, header = FALSE, quote = "\"'",
           col.names = c("nvar", "igr", "description", "unit", "dimensions"),
           stringsAsFactors = FALSE) %>%
  mutate_all(trimws) %>%
  as_tibble()

special_cases <- tibble(
  variable = c("SLZ", "HGT_CLASS"),
  description = c(
    "Soil depth",
    "Height bin for patch profiling"
  ),
  unit = c("m", "m"),
  dimensions = c("nzg", "ff_nhgt"),
  code_variable = c("slz", "hgt_class"),
  in_history = TRUE,
  in_analysis = TRUE,
  in_daily = TRUE,
  in_monthly = TRUE,
  in_diurnal = TRUE,
  in_yearly = TRUE,
  in_tower = FALSE
)

# Read dimensions from `allocate` blocks
dimension_info <- grep("allocate\\(", sv2, value = TRUE) %>%
  str_remove("allocate") %>%
  str_remove("^\\(") %>%
  str_remove("\\)$") %>%
  str_remove_all(" +") %>%
  str_match("(.*?)\\((.*)\\)$") %>%
  `colnames<-`(c("dimension_string", "code_variable", "dimensions")) %>%
  as_tibble() %>%
  mutate(code_variable = tolower(code_variable)) %>%
  distinct()

ed2_variables <- bind_cols(vtable_args, meta_args) %>%
  bind_rows(vtable_sca_args) %>%
  # Remove surrounding parentheses
  mutate_all(function(x) str_remove(str_remove(x, "^'"), "'$")) %>%
  # Exclude columns that contain no information
  select(code_variable, glob_id, info_string, description, unit) %>%
  mutate(
    variable = str_extract(info_string, "^[A-Z1-9_]+"),
    in_history = grepl("hist", info_string),
    in_analysis = grepl("anal|fast_keys", info_string),
    in_daily = grepl("dail(_keys)?", info_string),
    in_monthly = grepl("mont|eorq_keys", info_string),
    in_diurnal = grepl("dcyc|eorq_keys", info_string),
    in_yearly = grepl("year", info_string),
    in_tower = grepl("opti|fast_keys", info_string),
    # Clean up unit string
    unit = trimws(unit) %>%
      str_remove("^\\[ *") %>%
      str_remove(" *]$") %>%
      str_remove(" *#+ *$") %>%
      na_if("NA") %>%
      na_if("-") %>%
      na_if("--") %>%
      na_if("---") %>%
      na_if("----"),
    code_variable = tolower(code_variable)
  ) %>%
  inner_join(dimension_info, "code_variable") %>%
  bind_rows(special_cases) %>%
  select(
    variable, description, unit, dimensions, code_variable,
    starts_with("in_"), glob_id, info_string
  ) %>%
  mutate(
    # Some variables are missing descriptions and units
    description = case_when(
      variable == "RUNOFF" ~ "Water runoff",
      variable == "QRUNOFF" ~ "Water runoff",
      variable == "SWLIQ" ~ "",
      variable == "NPOLYGONS_GLOBAL" ~ "Number of polygons",
      variable == "NSITES_GLOBAL" ~ "Number of sites",
      variable == "NPATCHES_GLOBAL" ~ "Number of patches",
      variable == "NCOHORTS_GLOBAL" ~ "Number of cohorts",
      variable == "NZG" ~ "Number of soil levels",
      variable == "NZS" ~ "Number of water and snow levels",
      variable == "FF_NHGT" ~ "Number of height classes",
      variable == "NDCYCLE" ~ "Number of diurnal cycle time-steps",
      variable == "ISOILFLG" ~ "Type of soil used",
      variable == "SLXSAND" ~ "Prescribed soil sand fraction",
      variable == "SLXCLAY" ~ "Prescribed soil clay fraction",
      TRUE ~ description
    ),
    unit = case_when(
      variable == "RUNOFF" ~ "kg/m2/s",
      variable == "QRUNOFF" ~ "kg/m2/s",
      TRUE ~ unit
    )
  )

n_dup <- ed2_variables %>%
  count(variable) %>%
  filter(n > 1) %>%
  nrow()
stopifnot(n_dup == 0)

readr::write_csv(ed2_variables, here::here("inst", "ed2-state-variables.csv"))
