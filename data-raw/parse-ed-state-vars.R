library(stringr)
library(dplyr)

getrxp <- function(string, pattern) {
  m <- regexpr(pattern, string)
  regmatches(string, m)
}

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
  .[, 2]

meta_args

meta_rows <- grep("call metadata_", sv2)
meta_vals <- sv2[meta_rows]

var_rows <- vtable_rows + 2
desc_rows <- var_rows + 1
unit_rows <- desc_rows + 1

var_vals_raw <- state_vars_raw[var_rows]
var_vals <- getrxp(var_vals_raw, "[A-Z_]+")

desc_vals_raw <- state_vars_raw[desc_rows]
