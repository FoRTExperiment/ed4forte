fname <- list.files(outdir, "analysis-E", full.names = TRUE)[1]

all_vars %>%
  dplyr::filter(variable == "REPRO_PA")
