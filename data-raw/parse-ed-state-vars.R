library(stringr)
library(dplyr)
library(tidyr)

getrxp <- function(string, pattern) {
  m <- regexpr(pattern, string)
  regmatches(string, m)
}

# Path to ED2 source file -- change as necessary for your code
state_vars_file <- "~/Projects/edmodel/ed2-mpiao-pull/ED/src/memory/ed_state_vars.F90"
state_vars_raw <- readLines(state_vars_file)
state_vars_raw <- trimws(state_vars_raw)
state_vars_raw <- grep("^!", state_vars_raw, invert = TRUE, value = TRUE)
state_vars_raw <- state_vars_raw[state_vars_raw != ""]

sv_raw <- gsub("!.*", "", state_vars_raw)

sv2 <- character(length(sv_raw))
i <- 1
j <- 1
while (i <= length(state_vars_raw)) {
  s <- state_vars_raw[i]
  while (grepl("&", s)) {
    s <- gsub("&", "", s)
    i <- i + 1
    s <- paste0(s, state_vars_raw[i])
  }
  sv2[j] <- s
  j <- j + 1
  i <- i + 1
}
sv2 <- sv2[seq(1, j - 1)]

vtable_get_args <- function(x) {
  x %>%
    str_remove("\\) *$") %>%
    str_split(", *") %>%
    do.call(what = rbind) %>%
    apply(2, trimws)
}

vtable_sca_vals <- grep("call vtable_edio_[ir]_sca", sv2, value = TRUE)
vtable_sca_parse <- vtable_sca_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2)
vtable_sca_call <- vtable_sca_parse[, 1]
vtable_sca_args <- vtable_get_args(vtable_sca_parse[, 2])

vtable_vals <- grep("call vtable_edio_[ir] *\\(", sv2, value = TRUE)
vtable_parse <- vtable_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2)
vtable_call <- vtable_parse[, 1]
vtable_args <- vtable_get_args(vtable_parse[, 2])

meta_vals <- grep("call metadata_edio", sv2, value = TRUE)

meta_args_raw <- meta_vals %>%
  str_remove("^call +") %>%
  str_split_fixed(fixed("("), 2) %>%
  .[, 2] %>%
  str_remove("\\) *$")

meta_args <- meta_args_raw %>%
  str_split_fixed(fixed(","), 5)

vtable_first_four <- vtable_args[1:4, ]
vtable_rest <- vtable_args[-c(1:4), ]

ed2_variables <- cbind(vtable_rest, meta_args) %>%
  as_tibble(.name_repair = "unique") %>%
  mutate_all(trimws) %>%
  mutate_all(function(x) str_remove(str_remove(x, "^'"), "'$")) %>%
  # remove unnecessary columns
  select(
    code_variable = ...2,
    glob_id = ...6,
    info_string = ...10,
    description = ...13,
    unit = ...14,
    dimensions = ...15
  ) %>%
  mutate(
    variable = str_extract(info_string, "^[A-Z_]+"),
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
      na_if("----")
  ) %>%
  select(
    variable, description, unit, dimensions, code_variable,
    starts_with("in"), glob_id, info_string, everything()
  )

usethis::use_data(ed2_variables, internal = TRUE, overwrite = TRUE)
