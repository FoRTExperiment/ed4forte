library(PEcAn.data.atmosphere)

start_date <- "1979-01-01"
end_date <- "2019-12-31"
lat <- 45.5625
lon <- -84.6975
outdir <- file.path("unsynced-data", "narr")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

future::plan("multicore")
dl <- download.NARR_site(outdir, start_date, end_date, lat, lon)
