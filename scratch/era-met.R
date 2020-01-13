# Experimenting with ERA5 meteorology
library(reticulate)
cdsapi <- reticulate::import("cdsapi")
cclient <- cdsapi$Client()

# Full data documentation:
# https://confluence.ecmwf.int/display/CKB/ERA5+data+documentation
variables <- tibble::tribble(
  ~cf_name, ~units, ~api_name, ~ncdf_name,
  "air_temperature", "Kelvin", "2m_temperature", "t2m",
  "air_pressure", "Pa", "surface_pressure", NA_character_,
  NA_character_, "Kelvin", "2m_dewpoint_temperature", NA_character_,
  "precipitation_flux", "kg/m2/s", "total_precipitation", NA_character_,
  "eastward_wind", "m/s", "10m_u_component_of_wind", NA_character_,
  "northward_wind", "m/s", "10m_v_component_of_wind", NA_character_,
  "surface_downwelling_shortwave_flux_in_air", "W/m2", "surface_solar_radiation_downwards", NA_character_,
  "surface_downwelling_longwave_flux_in_air", "W/m2", "surface_thermal_radiation_downwards", NA_character_
)

lat.in <- 45.5625
lon.in <- -84.6975
area <- rep(round(c(lat.in, lon.in) * 4) / 4, 2)

cclient$retrieve(
  "reanalysis-era5-single-levels",
  list(
    product_type = "reanalysis",
    format = "netcdf",
    year = 1979,
    variable = variables[["api_name"]],
    month = seq(1, 12, 1),
    day = seq(1, 31, 1),
    time = "00/to/23/by/1",
    area = area,
    grid = c(0.25, 0.25)
  ),
  "era-1979.nc"
)

lat.in <- 45.5625
lon.in <- -84.6975
area <- rep(round(c(lat.in, lon.in) * 10) / 10, 2)

cdsapi <- reticulate::import("cdsapi")
cclient <- cdsapi$Client()
cclient$retrieve(
  "reanalysis-era5-land",
  list(
    format = "grib",
    variable = c("surface_solar_radiation_downwards",
                 "surface_thermal_radiation_downwards"),
    year = 1981,
    month = 1,
    day = 1,
    time = "00/to/23/by/1",
    area = area,
    grid = c(0.1, 0.1)
  ),
  "download.grib"
)


x <- rgdal::readGDAL("download.grib")
x2 <- rgdal::readGDAL("dl2.tif")
nc <- ncdf4::nc_open("dl3.nc")
meta <- lapply(names(nc$var), ncdf4::ncatt_get, nc = nc)
meta2 <- lapply(meta, do.call, what = data.frame)
meta_df <- do.call(rbind, meta2[-1])
xinfo <- rgdal::GDALinfo("download.grib", returnCategoryNames = TRUE)

