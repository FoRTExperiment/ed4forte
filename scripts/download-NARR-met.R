library(ed4forte)

stopifnot(
  requireNamespace("here", quietly = TRUE),
  requireNamespace("future", quietly = TRUE),
  requireNamespace("PEcAn.ED2", quietly = TRUE)
)

start_date <- "1979-01-01"
end_date <- "2019-12-31"
lat <- 45.5625
lon <- -84.6975
outdir <- here::here("unsynced-data", "narr")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

future::plan("multicore")
dl <- download.NARR_site(outdir, start_date, end_date, lat, lon)

outdir_ed <- here::here("unsynced-data", "narr-ed")
ed_met <- PEcAn.ED2::met2model.ED2(outdir, "NARR", outdir_ed,
                                   start_date, end_date,
                                   lat = lat, lon = lon)
