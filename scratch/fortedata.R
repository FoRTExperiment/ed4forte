## devtools::install_github("FoRTExperiment/fortedata")
devtools::load_all()

library(fortedata)
library(dplyr)
library(readr)

narr_ed <- here::here("unsynced-data", "ed-input-data", "NARR-ED2",
                      "ED_MET_DRIVER_HEADER")

base_outdir <- here::here("unsynced-data/test-outputs")
dir.create(base_outdir, showWarnings = FALSE, recursive = TRUE)

outdir <- file.path(base_outdir, "fd-init")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

pss_cols <- c("time", "patch", "trk", "age", "area",
              "water", "fsc", "stsc", "stsl", "ssc",
              "lai", "msn", "fsn")

pss_default <- tibble(
  time = -999, water = -999, lai = -999,
  fsc = 0.46, stsc = 3.9, stsl = 3.9,
  ssc = 0.003, msn = 1, fsn = 1
)

pss_df <- tibble(
  time = -999, patch = "A", trk = 3, age = 100, area = 1,
  water = -999, lai = -999
)

pss_df <- tibble(
  time = -999, patch = "A", trk = 3, age = 100, area = 1,
  water = -999, fsc = 1, stsc = 5, stsl = 5, ssc = 0.01,
  lai = -999, msn = 1, fsn = 1,
  nep = -999, gpp = -999, rh = -999
)
write_csv(pss_df, coords_prefix(file.path(outdir, "testinit"), "pss"))
css_df <- tibble(
  time = -999, patch = "A", cohort = "A1", dbh = 25,
  hite = -999, pft = 9, n = 0.0001,
  bdead = -999, balive = -999, lai = -999
)
write_csv(css_df, coords_prefix(file.path(outdir, "testinit"), "css"))

p <- run_ed2(
  outdir, "2000-07-01", "2000-08-01",
  ED_MET_DRIVER_DB = narr_ed,
  IED_INIT_MODE = 6,
  INCLUDE_THESE_PFT = c(9:11, 6),
  SFILIN = file.path(outdir, "testinit")
)

list.files(outdir)
e <- read_monthly_file(list.files(outdir, "analysis-E", full.names = TRUE))
e$scalar$
e$cohort$DBH

##################################################
# Now, real FoRTE inventory
pss_cols <- c("time", "patch", "trk", "age", "area",
              "water", "fsc", "stsc", "stsl", "ssc",
              "lai", "msn", "fsn")

pss_default <- tibble(
  time = -999, water = -999, lai = -999,
  fsc = 0.46, stsc = 3.9, stsl = 3.9,
  ssc = 0.003, msn = 1, fsn = 1
)

patches <- fd_subplots() %>%
  mutate(
    patch = paste(Plot, Subplot, Replicate, sep = "-"),
    # TODO: Adjust these values accordingly
    trk = 3,
    age = 100,
    area = Subplot_area_m2 / sum(Subplot_area_m2)
  ) %>%
  mutate(!!!pss_default[, setdiff(colnames(pss_default), colnames(.))]) %>%
  select(!!pss_cols, everything())

css_cols <- c("time", "patch", "cohort", "dbh",
              "hite", "pft", "n", "bdead", "balive", "lai")
css_default <- tibble(
  time = -999, hite = -999,
  bdead = -999, balive = -999, lai = -999
)

spp_pft <- system.file("pfts-species.csv", package = "ed4forte") %>%
  read_csv(col_types = "cc")

css <- fd_inventory() %>%
  inner_join(patches, c("Replicate", "Plot", "Subplot")) %>%
  # Inner join here to exclude unmatched species
  inner_join(spp_pft, c("Species" = "species")) %>%
  mutate(
    cohort = row_number(),
    n = 1 / Subplot_area_m2,
    !!!css_default[, setdiff(colnames(css_default), colnames(.))]
  ) %>%
  rename(dbh = DBH_cm) %>%
  select(!!css_cols)
pss <- patches %>% select(!!pss_cols)

fd_outdir <- file.path(base_outdir, "real-init")
dir.create(fd_outdir, showWarnings = FALSE, recursive = TRUE)
fd_prefix <- file.path(fd_outdir, "fortedata")
write_csv(css, coords_prefix(fd_prefix, "css"))
write_csv(pss, coords_prefix(fd_prefix, "pss"))
p2 <- run_ed2(
  fd_outdir, "2000-06-01", "2000-09-01",
  ED_MET_DRIVER_DB = narr_ed,
  SFILIN = fd_prefix
)
writeLines(tail(readLines(p2$get_output_file())))
