lat.in <- 45.5625
lon.in <- -84.6975

url_orig <- "https://rda.ucar.edu/thredds/dodsC/aggregations/e/ds626.0/9/TP"

nc <- ncdf4::nc_open(paste0(
  "https://ashiklom%40bu.edu:Thisis4theNARR@rda.ucar.edu/",
  "thredds/dodsC/aggregations/e/ds626.0/9/TP"
))
nc

ncss_query <- glue::glue(
  "https://ashiklom%40bu.edu:Thisis4theNARR@rda.ucar.edu/",
  "/thredds/ncss/grid/aggregations/e/ds626.0/9/TP?",
  "var=Vertical_integral_of_temperature_entire_atmosphere&",
  "var=10_metre_U_wind_component_surface&",
  "var=10_metre_V_wind_component_surface&",
  "latitude=45.5625&",
  "longitude=-84.6975&",
  "time_start=1900-01-01T00%3A00%3A00Z&",
  "time_end=1900-12-31T21%3A00%3A00Z&",
  "timeStride=1&",
  "vertCoord=&",
  "accept=netcdf4-classic"
)
download.file(ncss_query, "~/Downloads/zz-ncdf.nc")
mync <- ncdf4::nc_open("~/Downloads/zz-ncdf.nc")


raw_csv <- readr::read_csv(ncss_query)

plot(raw_csv[["time"]], raw_csv[[5]] / 10000, type = "l")


## ncss_url <- "https://rda.ucar.edu/thredds/ncss/grid/aggregations/e/ds626.0/9/TP?var=Vertical_integral_of_temperature_entire_atmosphere&var=10_metre_U_wind_component_surface&var=10_metre_V_wind_component_surface&latitude=45.5625&longitude=-84.6975&time_start=1900-01-01T00%3A00%3A00Z&time_end=1900-12-31T21%3A00%3A00Z&timeStride=1&vertCoord=&accept=csv"
ncss_url2 <- paste0(
  "https://ashiklom%40bu.edu:Thisis4theNARR@rda.ucar.edu",
  "/thredds/ncss/grid/aggregations/e/ds626.0/9/TP?",
  "var=Vertical_integral_of_temperature_entire_atmosphere&",
  "var=10_metre_U_wind_component_surface&",
  "var=10_metre_V_wind_component_surface&",
  "latitude=45.5625&",
  "longitude=-84.6975&",
  "time_start=1900-01-01T00%3A00%3A00Z&",
  "time_end=1900-12-31T21%3A00%3A00Z&",
  "timeStride=1&",
  "vertCoord=&",
  "accept=csv"
)
raw_lines2 <- readLines(ncss_url2)

current_var <-

ncss_query <- glue::glue(
  url, "?",
  "var={current_var}&",
  "south={lat.in}&",
  "west={lon.in}&",
  # Add tiny amount to latitude and longitude to satisfy
  # non-point condition, but still be within grid cell.
  "north={lat.in + 5e-6}&",
  "east={lon.in + 5e-6}&",
  # Year starts at 00:00:00 and ends at 21:00:00
  "time_start={year}-01-01T00:00:00Z&",
  "time_end={year}-12-31T21:00:00Z&",
  "accept=netcdf"
)
