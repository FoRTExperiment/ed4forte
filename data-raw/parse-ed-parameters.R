library(dplyr)
library(stringr)

stopifnot(requireNamespace("here", quietly = TRUE))
source(here::here("data-raw", "helpers.R"))

## ed2_base_path <- "https://raw.githubusercontent.com/EDmodel/ED2/master/"
ed2_base_path <- "~/Projects/edmodel/ed2"
param_file <- file.path(ed2_base_path, "ED", "src", "io", "ed_xml_config.f90")
param_file_raw <- readLines(param_file)

param_file_proc <- read_raw_fortran(param_file_raw)

getconfigs <- grep("call +getConfig", param_file_proc, value = TRUE)
conf_proc <- str_match(getconfigs, "getConfig([[:alnum:]]+) +\\(([[:graph:]]+)\\)")
conf_proc2 <- conf_proc[!is.na(conf_proc[,1]),]

args <- conf_proc2[, 3] %>%
  read.csv(text = ., quote = "\"'", header = FALSE, row.names = NULL,
           stringsAsFactors = FALSE) %>%
  as_tibble() %>%
  mutate(type = conf_proc2[, 2]) %>%
  select(parameter = V1, target = V2, type) %>%
  distinct()

write_csv(args, here::here("inst", "ed2-parameters.csv"))
