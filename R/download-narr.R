#' Download NARR time series for a single site
#'
#' @param outfolder Target directory for storing output
#' @param start_date Start date for met data
#' @param end_date End date for met data
#' @param lat.in Site latitude coordinate
#' @param lon.in Site longitude coordinate
#' @param overwrite Overwrite existing files? Default=`FALSE`
#' @param verbose Turn on verbose output? Default=`FALSE`
#' @param progress Print a progress bar as data are being downloaded? Default = `TRUE`
#' @param narr_cache_dir Directory where to cache downloaded data. Default is
#'   `<outfolder>/narr_cache`.
#' @param overwrite_cache Delete existing cache? Default = `FALSE`
#' @param parallel Download in parallel? Default = `TRUE`
#' @param ncores Number of cores for parallel download. Default is
#' `parallel::detectCores()`
#'
#' @param ... Additional arguments (not used)
#' @inheritParams robustly
#' @examples
#'
#' \dontrun{
#' download.NARR_site(tempdir(), "2001-01-01", "2001-01-12", 43.372, -89.907)
#' }
#'
#'
#' @export
#'
#' @author Alexey Shiklomanov
download.NARR_site <- function(outfolder,
                               start_date, end_date,
                               lat.in, lon.in,
                               overwrite = FALSE,
                               verbose = FALSE,
                               progress = TRUE,
                               narr_cache_dir = file.path(outfolder,
                                                          "narr_cache"),
                               overwrite_cache = FALSE,
                               parallel = TRUE,
                               ncores = parallel::detectCores(),
                               silent = TRUE,
                               ...) {

  if (verbose) message("Downloading NARR data")
  narr_data <- get_NARR_thredds(
    start_date, end_date, lat.in, lon.in,
    progress = progress,
    narr_cache_dir = narr_cache_dir,
    overwrite_cache = overwrite_cache,
    parallel = parallel,
    ncores = ncores,
    silent = silent
  )
  dir.create(outfolder, showWarnings = FALSE, recursive = TRUE)

  date_limits_chr <- strftime(range(narr_data$datetime), "%Y-%m-%d %H:%M:%S", tz = "UTC")

  narr_byyear <- narr_data %>%
    dplyr::mutate(year = lubridate::year(datetime)) %>%
    dplyr::group_by(year) %>%
    tidyr::nest()

  # Prepare result data frame
  result_full <- narr_byyear %>%
    dplyr::mutate(
      file = file.path(outfolder, paste("NARR", year, "nc", sep = ".")),
      host = NA_character_,
      start_date = date_limits_chr[1],
      end_date = date_limits_chr[2],
      mimetype = "application/x-netcdf",
      formatname = "CF Meteorology",
    )

  lat <- ncdf4::ncdim_def(
    name = "latitude",
    units = "degree_north",
    vals = lat.in,
    create_dimvar = TRUE
  )
  lon <- ncdf4::ncdim_def(
    name = "longitude",
    units = "degree_east",
    vals = lon.in,
    create_dimvar = TRUE
  )

  narr_proc <- result_full %>%
    dplyr::mutate(
      data_nc = purrr::map2(data, file, prepare_narr_year, lat = lat, lon = lon)
    )

  results <- dplyr::select(result_full, -data)
  return(invisible(results))
} # download.NARR_site

#' Write NetCDF file for a single year of data
#'
#' @param dat NARR tabular data for a single year ([get_NARR_thredds])
#' @param file Full path to target file
#' @param lat_nc `ncdim` object for latitude
#' @param lon_nc `ncdim` object for longitude
#' @inheritParams download.NARR_site
#' @return List of NetCDF variables in data. Creates NetCDF file containing
#' data as a side effect
prepare_narr_year <- function(dat, file, lat_nc, lon_nc, verbose = FALSE) {
  starttime <- min(dat$datetime)
  starttime_f <- strftime(starttime, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  time <- difftime(dat$datetime, starttime) %>%
    as.numeric() %>%
    udunits2::ud.convert("seconds", "hours")
  time_nc <- ncdf4::ncdim_def(
    name = "time",
    units = paste0("hours since ", starttime_f),
    vals = time,
    create_dimvar = TRUE,
    unlim = TRUE
  )
  nc_values <- dplyr::select(dat, narr_all_vars$CF_name)
  ncvar_list <- purrr::map(
    colnames(nc_values),
    col2ncvar,
    dims = list(lat_nc, lon_nc, time_nc)
  )
  nc <- ncdf4::nc_create(file, ncvar_list, verbose = verbose)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  purrr::iwalk(nc_values, ~ncdf4::ncvar_put(nc, .y, .x, verbose = verbose))
  invisible(ncvar_list)
}

#' Create `ncvar` object from variable name
#'
#' @param variable CF variable name
#' @param dims List of NetCDF dimension objects (passed to
#' `ncdf4::ncvar_def(..., dim)`)
#' @return `ncvar` object (from `ncvar_def`)
col2ncvar <- function(variable, dims) {
  var_info <- narr_all_vars %>% dplyr::filter(CF_name == variable)
  ncdf4::ncvar_def(
    name = variable,
    units = var_info$units,
    dim = dims,
    missval = -999,
  )
}

#' Retrieve NARR data using thredds
#'
#' @param start_date Start date for meteorology
#' @param end_date End date for meteorology
#' @param lat.in Latitude coordinate
#' @param lon.in Longitude coordinate
#' @param progress Whether or not to show a progress bar (default = `TRUE`).
#' Requires the `progress` package to be installed.
#' @param drop_outside Whether or not to drop dates outside of `start_date` to
#' `end_date` range (default = `TRUE`).
#' @inheritParams download.NARR_site
#' @return `tibble` containing time series of NARR data for the given site
#' @author Alexey Shiklomanov
#' @examples
#'
#' \dontrun{
#' dat <- get_NARR_thredds("2008-01-01", "2008-01-15", 43.3724, -89.9071)
#' }
#'
#' @export
get_NARR_thredds <- function(start_date, end_date, lat.in, lon.in,
                             progress = TRUE,
                             narr_cache_dir = "narr_cache",
                             overwrite_cache = FALSE,
                             drop_outside = TRUE,
                             parallel = TRUE,
                             ncores = 1,
                             silent = FALSE) {

  stopifnot(
    length(start_date) == 1,
    length(end_date) == 1,
    length(lat.in) == 1,
    length(lon.in) == 1
  )

  narr_start <- lubridate::ymd("1979-01-01")
  # NARR is updated monthly
  # Set end day to the last day of the previous month
  # (e.g. March 31 if today is April 10)
  today <- lubridate::as_date(Sys.Date())
  narr_end <- today - lubridate::days(lubridate::mday(today))

  start_date <- lubridate::as_date(start_date)
  end_date <- lubridate::as_date(end_date)

  stopifnot(start_date >= narr_start,
            end_date <= narr_end)

  if (overwrite_cache) {
    unlink(narr_cache_dir, recursive = TRUE, force = TRUE)
  }
  dir.create(narr_cache_dir, showWarnings = FALSE)

  dates <- seq(start_date, end_date, by = "1 day")

  flx_df_all <- generate_narr_url(dates, "flx") %>%
    dplyr::mutate(datatype = "flx")
  sfc_df_all <- generate_narr_url(dates, "sfc") %>%
    dplyr::mutate(datatype = "sfc")
  both_df_all <- dplyr::bind_rows(flx_df_all, sfc_df_all) %>%
    dplyr::mutate(cachefile = file.path(
      narr_cache_dir,
      paste(datatype, startdate, sep = "-")
    ))
  both_df <- both_df_all %>%
    dplyr::filter(!file.exists(cachefile))
  both_cached <- both_df_all %>%
    dplyr::filter(file.exists(cachefile))
  message(
    "Found ", nrow(both_cached),
    " cached NARR files that can be skipped. ",
    "Still have to download ",
    nrow(both_df), " NARR files."
  )

  # Load dimensions, etc. from first netCDF file
  # NOTE: Need to use `flx_df_all` here for special case if all files are cached.
  xy_cachefile <- file.path(narr_cache_dir, "xy")
  if (file.exists(xy_cachefile)) {
    xy <- as.integer(readLines(xy_cachefile))
    names(xy) <- c("x", "y")
  } else {
    nc1 <- robustly(ncdf4::nc_open, n = 20, timeout = 0.5, silent = silent)(flx_df_all$url[1])
    on.exit(ncdf4::nc_close(nc1), add = TRUE)
    xy <- latlon2narr(nc1, lat.in, lon.in)
    writeLines(as.character(xy), xy_cachefile)
  }

  mapfun <- purrr::pmap
  if (parallel) {
    stopifnot(requireNamespace("furrr"), quietly = TRUE)
    mapfun <- purrr::partial(furrr::future_pmap, .progress = progress)
    progress <- FALSE
  }

  # Retrieve remaining variables by iterating over URLs
  if (progress && requireNamespace("progress")) {
    pb <- progress::progress_bar$new(
      total = nrow(flux_df) * nrow(narr_flx_vars) +
        nrow(sfc_df) * nrow(narr_sfc_vars),
      format = "[:bar] :current/:total ETA: :eta"
    )
  } else {
    pb <- NULL
  }

  both_data_raw <- both_df %>%
    dplyr::mutate(
      data = mapfun(
        list(url = url, cachefile = cachefile, datatype = datatype),
        robustly(get_narr_url, n = 20, timeout = 1, silent = silent),
        xy = xy,
        pb = pb
      )
    )

  both_data_cached <- both_cached %>%
    dplyr::mutate(
      data = purrr::map(
        cachefile,
        read.table,
        header = TRUE,
        sep = "\t"
      )
    )

  both_data <- dplyr::bind_rows(both_data_raw, both_data_cached)
  flx_data <- both_data %>%
    dplyr::filter(datatype == "flx") %>%
    post_process() %>%
    dplyr::select(datetime, narr_flx_vars$CF_name)
  sfc_data <- both_data %>%
    dplyr::filter(datatype == "sfc") %>%
    post_process() %>%
    dplyr::select(datetime, narr_sfc_vars$CF_name)

  met_data <- flx_data %>%
    dplyr::full_join(sfc_data, by = "datetime") %>%
    dplyr::arrange(datetime)

  if (drop_outside) {
    met_data <- met_data %>%
      dplyr::filter(
        datetime >= start_date,
        datetime < (end_date + lubridate::days(1))
      )
  }

  met_data
}

#' Post process raw NARR downloaded data frame
#'
#' @param dat Nested `tibble` from mapped call to [get_narr_url]
post_process <- function(dat) {
  dat %>%
    tidyr::unnest(data) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(datetime = startdate + lubridate::dhours(dhours)) %>%
    dplyr::select(-startdate, -dhours) %>%
    dplyr::select(datetime, dplyr::everything()) %>%
    dplyr::select(-url, url)
}

#' Generate NARR url from a vector of dates
#'
#' Figures out file names for the given dates, based on NARR's convoluted and
#' inconsistent naming scheme.
#'
#' @param dates Vector of dates for which to generate URL
#' @param datatype Type of NARR file -- either `flx` or `sfc`
#' @author Alexey Shiklomanov
generate_narr_url <- function(dates, datatype) {
  ngroup <- switch(
    datatype,
    "flx" = 8,
    "sfc" = 10
  )
  base_url <- paste(
    # Have to login, so use Alexey Shiklomanov's account
    "http://ashiklom%40bu.edu:Thisis4theNARR@rda.ucar.edu",
    "thredds", "dodsC", "files", "g", "ds608.0", "3HRLY",
    sep = "/"
  )
  tibble::tibble(date = dates) %>%
    dplyr::mutate(
      year = lubridate::year(date),
      month = lubridate::month(date),
      daygroup = daygroup(date, datatype)
    ) %>%
    dplyr::group_by(year, month, daygroup) %>%
    dplyr::summarize(
      startdate = min(date),
      url = sprintf(
        "%s/%d/NARR%s_%d%02d_%s.tar",
        base_url,
        unique(year),
        datatype,
        unique(year),
        unique(month),
        unique(daygroup)
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(startdate, url)
}

#' Assign daygroup tag for a given date
daygroup <- function(date, datatype) {
  mday <- lubridate::mday(date)
  mmax <- lubridate::days_in_month(date)
  if (datatype == "flx") {
    dplyr::case_when(
      mday %in% 1:8 ~ "0108",
      mday %in% 9:16 ~ "0916",
      mday %in% 17:24 ~ "1724",
      mday >= 25 ~ paste0(25, mmax)
    )
  } else if (datatype == "sfc") {
    dplyr::case_when(
      mday %in% 1:9 ~ "0109",
      mday %in% 10:19 ~ "1019",
      mday >= 20 ~ paste0(20, mmax)
    )
  }
}

#' Retrieve NARR data from a given URL
#'
#' @param url Full URL to NARR thredds file
#' @param xy Vector length 2 containing NARR coordinates
#' @param pb Progress bar R6 object (default = `NULL`)
#' @param cachefile Output file for caching results
#' @inheritParams generate_narr_url
#' @author Alexey Shiklomanov
get_narr_url <- function(url, xy, datatype, cachefile, pb = NULL) {
  stopifnot(length(xy) == 2, length(url) == 1, is.character(url),
            datatype %in% c("flx", "sfc"))
  nc <- ncdf4::nc_open(url)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  flx <- datatype == "flx"
  timevar <- switch(
    datatype,
    "flx" = "time",
    "sfc" = "reftime"
  )
  dhours <- ncdf4::ncvar_get(nc, timevar)
  # HACK: Time variable seems inconsistent.
  # Sometimes starts at 0, sometimes offset by 3.
  # This is a hack to make it always start at zero
  if (dhours[1] == 3) dhours <- dhours - 3
  narr_vars <- switch(
    datatype,
    "flx" = narr_flx_vars,
    "sfc" = narr_sfc_vars
  )
  result <- purrr::pmap(
    narr_vars %>% dplyr::select(variable = NARR_name, unit = units),
    read_narr_var,
    nc = nc, xy = xy, datatype = datatype, pb = pb
  )
  names(result) <- narr_vars$CF_name
  result2 <- dplyr::bind_cols(dhours = dhours, result)
  write.table(result2, cachefile, sep = "\t", row.names = FALSE)
  result2
}

#' Read a specific variable from a NARR NetCDF file
#'
#' @param nc `ncdf4` connection object
#' @param variable NARR name of variable to retrieve
#' @param unit Output unit of variable to retrieve
#' @inheritParams get_narr_url
#' @author Alexey Shiklomanov
read_narr_var <- function(nc, xy, variable, unit, datatype, pb = NULL) {
  stopifnot(datatype %in% c("flx", "sfc"))
  if (datatype == "flx") {
    # Third dimension is height above ground -- first index is 2m above ground
    start <- c(xy, 1, 1)
    count <- c(1, 1, 1, -1)
  } else if (datatype == "sfc") {
    # Third dimension is reference time; only has one index
    start <- c(xy, 1, 1)
    count <- c(1, 1, -1, -1)
  }
  nc_unit <- ncdf4::ncatt_get(nc, variable, "units")$value
  out <- ncdf4::ncvar_get(nc, variable, start = start, count = count)
  # Precipitation is a special case -- unit is actually precipitation per 3 hours
  # So, divide by seconds in 3 hours and change unit accordingly
  if (variable == "Total_precipitation_surface_3_Hour_Accumulation") {
    nc_unit <- paste0(nc_unit, "/s")
    out <- out / udunits2::ud.convert(3, "hours", "seconds")
  }
  final <- udunits2::ud.convert(out, nc_unit, unit)
  if (!is.null(pb)) pb$tick()
  final
}

#' NARR flux and sfc variables
narr_flx_vars <- tibble::tribble(
  ~CF_name, ~NARR_name, ~units,
  "air_temperature", "Temperature_height_above_ground", "Kelvin",
  "air_pressure", "Pressure_height_above_ground", "Pascal",
  "eastward_wind", "u-component_of_wind_height_above_ground", "m/s",
  "northward_wind", "v-component_of_wind_height_above_ground", "m/s",
  "specific_humidity", "Specific_humidity_height_above_ground", "g/g"
)

#' @rdname narr_flx_vars
narr_sfc_vars <- tibble::tribble(
  ~CF_name, ~NARR_name, ~units,
  "surface_downwelling_longwave_flux_in_air", "Downward_longwave_radiation_flux_surface_3_Hour_Average", "W/m2",
  "surface_downwelling_shortwave_flux_in_air", "Downward_shortwave_radiation_flux_surface_3_Hour_Average", "W/m2",
  "precipitation_flux", "Total_precipitation_surface_3_Hour_Accumulation", "kg/m2/s",
)

#' @rdname narr_flx_vars
narr_all_vars <- dplyr::bind_rows(narr_flx_vars, narr_sfc_vars)

#' Convert latitude and longitude coordinates to NARR indices
#'
#' @inheritParams read_narr_var
#' @inheritParams get_NARR_thredds
#' @return Vector length 2 containing NARR `x` and `y` indices, which can be
#' used in `ncdf4::ncvar_get` `start` argument.
#' @author Alexey Shiklomanov
latlon2narr <- function(nc, lat.in, lon.in) {
  narr_x <- ncdf4::ncvar_get(nc, "x")
  narr_y <- ncdf4::ncvar_get(nc, "y")
  ptrans <- latlon2lcc(lat.in, lon.in)
  x_ind <- which.min((ptrans$x - narr_x) ^ 2)
  y_ind <- which.min((ptrans$y - narr_y) ^ 2)
  c(x = x_ind, y = y_ind)
}

#' Convert latitude and longitude to x-y coordinates (in km) in Lambert
#' conformal conic projection (used by NARR)
#'
#' @inheritParams get_NARR_thredds
#' @return `sp::SpatialPoints` object containing transformed x and y
#' coordinates, in km, which should match NARR coordinates
#' @importFrom rgdal checkCRSArgs
  # ^not used directly here, but needed by sp::CRS.
  # sp lists rgdal in Suggests rather than Imports,
  # so importing it here to ensure it's available at run time
#' @author Alexey Shiklomanov
#' @export
latlon2lcc <- function(lat.in, lon.in) {
  pll <- sp::SpatialPoints(list(x = lon.in, y = lat.in), sp::CRS("+proj=longlat +datum=WGS84"))
  CRS_narr_string <- paste(
    "+proj=lcc +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96",
    "+x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=km +no_defs"
  )
  CRS_narr <- sp::CRS(CRS_narr_string)
  ptrans <- sp::spTransform(pll, CRS_narr)
  ptrans
}
