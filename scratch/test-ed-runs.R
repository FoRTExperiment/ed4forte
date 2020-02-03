options(ed4forte.ed2_exe = normalizePath("~/Projects/edmodel/ed2-my-develop/ED/build/ed_2.2-opt"))

stopifnot(requireNamespace("here", quietly = TRUE))
devtools::load_all(here::here())

basedir <- here::here("unsynced-data")

narr_met <- file.path(basedir, "ed-input-data", "NARR-ED2",
                      "ED_MET_DRIVER_HEADER")

# Default run of ED2, from bare ground
pdefault <- run_ed2(
  file.path(basedir, "default"),
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met
)

if (interactive()) tail(readLines(pdefault$get_output_file()))

# Similar run, but create a mostly blank config file
blank_config <- tibble::tibble(
  num = c(9, 10, 11),
  is_tropical = 0
)
pblank_config <- run_ed2(
  file.path(basedir, "blank-config"),
  "1980-01-01", "1990-01-01",
  configxml = blank_config,
  ED_MET_DRIVER_DB = narr_met
)

# Similar run, but create a mostly blank config file
pquick_out <- file.path(basedir, "blank-config-quick")
pquick_config <- run_ed2(
  pquick_out,
  "1980-01-01", "1980-01-05",
  configxml = blank_config,
  ED_MET_DRIVER_DB = narr_met,
)
if (interactive()) tail(readLines(pquick_config$get_output_file()))
