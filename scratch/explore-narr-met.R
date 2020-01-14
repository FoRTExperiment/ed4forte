library(ncdf4)
library(here, include.only = "here")

narr_dir <- here("unsynced-data", "narr")
narr_files <- list.files(narr_dir, "\\.nc$", full.names = TRUE)

cruncep_dir <- file.path("..", "umbs-ed-inputs",
                         "met", "CRUNCEP_site_1-33")
cruncep_files <- list.files(cruncep_dir, "\\.nc$", full.names = TRUE)

narr1_nc <- nc_open(file.path(narr_dir, "NARR.1979.nc"))
ncep1_nc <- nc_open(file.path(cruncep_dir, "CRUNCEP.1979.nc"))

nc_get_time <- function(nc, timevar = "time") {
  att <- ncdf4::ncatt_get(nc, timevar)
  unit <- att$units
  rawvals <- ncdf4::ncvar_get(nc, timevar)
  posixunit <- "seconds since 1970-01-01T00:00:00Z"
  vals <- udunits2::ud.convert(rawvals, unit, posixunit)
  as.POSIXct(vals, tz = "UTC", origin = "1970-01-01")
}

narr_t <- nc_get_time(narr1_nc)
ncep_t <- nc_get_time(ncep1_nc)

v <- "air_temperature"
narr_temp <- ncvar_get(narr1_nc, v)
ncep_temp <- ncvar_get(ncep1_nc, v)
plot(narr_t, narr_temp, type = "l")
lines(ncep_t, ncep_temp, col = 2)

10800 / (60 * 60)
nc1 <- nc_open(narr_files[1])
airtemp <- ncvar_get(nc1, "air_temperature")

plot(airtemp, type = "l")
