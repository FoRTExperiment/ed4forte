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
pblank_out <- file.path(basedir, "blank-config")
dir.create(pblank_out, showWarnings = FALSE, recursive = TRUE)
write_configxml(list(
  list(num = 9, is_tropical = 0),
  list(num = 10, is_tropical = 0),
  list(num = 11, is_tropical = 0)
), file.path(pblank_out, "config.xml"))
pblank_config <- run_ed2(
  pblank_out,
  "1980-01-01", "1990-01-01",
  ED_MET_DRIVER_DB = narr_met,
  IEDCNFGF = file.path(pblank_out, "config.xml")
)

# Similar run, but create a mostly blank config file
pquick_out <- file.path(basedir, "blank-config-quick")
dir.create(pquick_out, showWarnings = FALSE, recursive = TRUE)
write_configxml(list(
  list(num = 9, is_tropical = 0),
  list(num = 10, is_tropical = 0),
  list(num = 11, is_tropical = 0)
), file.path(pquick_out, "config.xml"))
pquick_config <- run_ed2(
  pquick_out,
  "1980-01-01", "1980-01-05",
  ED_MET_DRIVER_DB = narr_met,
  IEDCNFGF = file.path(pquick_out, "config.xml")
)
if (interactive()) tail(readLines(pquick_config$get_output_file()))
