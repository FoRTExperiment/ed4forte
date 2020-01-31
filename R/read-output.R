#' Read monthly (-E-) file
#'
#' @param fname File name
#' @param .pb Optional progress bar object
#' @return List of four `data.frames`, one each for scalar, cohort, soil, and
#'   PFT variables.
#' @importFrom magrittr %>%
#' @export
read_monthly_file <- function(fname, .pb = NULL) {
  hf <- ncdf4::nc_open(fname)
  on.exit(ncdf4::nc_close(hf))
  dt <- get_datetime(fname)

  all_vars <- ed2_variable_info() %>%
    dplyr::filter(in_monthly)

  cohort_vars <- all_vars %>%
    dplyr::filter(dimensions == "icohort") %>%
    dplyr::pull(variable)

  if (cohort_vars[1] %in% names(hf$var)) {
    cohort_data <- purrr::map(cohort_vars, ncget, nc = hf) %>%
      setNames(cohort_vars) %>%
      purrr::discard(is.null)
    # Radiation profile is a special case
    rad_profile <- ncdf4::ncvar_get(hf, "MMEAN_RAD_PROFILE_CO") %>%
      t() %>%
      `colnames<-`(c("par_beam_down", "par_beam_up", "par_diff_down",
                     "par_diff_up", "nir_beam_down",
                     "nir_beam_up", "nir_diff_down",
                     "nir_diff_up", "tir_diff_down", "tir_diff_up")) %>%
      tibble::as_tibble()
    mort_rates <- ncdf4::ncvar_get(hf, "MMEAN_MORT_RATE_CO") %>%
      t() %>%
      `colnames<-`(paste0("mmean_mort_rate_co_", c("aging", "carbon",
                                                "treefall", "cold",
                                                "disturbance"))) %>%
      tibble::as_tibble()
    cohort_out <- tibble::tibble(datetime = dt, !!!cohort_data,
                                 !!!rad_profile, !!!mort_rates)
  } else {
    warning("File ", fname, " has no cohort data!")
    cohort_out <- NULL
  }

  scalar_vars <- all_vars %>%
    dplyr::filter(
      dimensions %in% c(NA, "isite", "ipoly"),
      # These are not actually scalar, just unknown dims, so we exclude them
      !variable %in% c("NTEXT_SOIL", "DISTURBANCE_RATES", "REPRO_PA")
    ) %>%
    dplyr::pull(variable)

  scalar_data <- purrr::map(scalar_vars, ncget, nc = hf) %>%
    setNames(scalar_vars) %>%
    purrr::discard(is.null)
  scalar_out <- tibble::tibble(datetime = dt, !!!scalar_data)

  soil_vars <- all_vars %>%
    dplyr::filter(dimensions %in% c("nzg", "nzg,ipatch", "nzg,ipoly")) %>%
    dplyr::pull(variable)

  soil_data <- purrr::map(soil_vars, ncget, nc = hf) %>%
    setNames(soil_vars) %>%
    purrr::discard(is.null)
  soil_out <- tibble::tibble(datetime = dt, !!!soil_data)

  py_vars <- all_vars %>%
    dplyr::filter(dimensions == "n_pft,n_dbh,ipoly") %>%
    dplyr::pull(variable)

  py_data <- purrr::map(py_vars, ncget, nc = hf) %>%
    # Sum across DBH classes
    purrr::map(~rowSums(.x)) %>%
    setNames(py_vars) %>%
    purrr::discard(is.null)
  py_out <- tibble::tibble(datetime = dt, pft = seq(1, 17), !!!py_data)

  list(
    scalar = scalar_out,
    cohort = cohort_out,
    soil = soil_out,
    pft = py_out
  )
}

get_datetime <- function(fname) {
  datestring <- fname %>%
    fs::path_file() %>%
    stringr::str_extract(paste("[[:digit:]]{4}",
                               "[[:digit:]]{2}", "[[:digit:]]{2}", "[[:digit:]]{6}",
                               sep = "-"))
  year <- as.numeric(substring(datestring, 1, 4))
  month <- as.numeric(substring(datestring, 6, 7))
  day <- as.numeric(substring(datestring, 9, 10))
  # To accommodate monthly files
  if (day == 0) day <- 1
  hr <- as.numeric(substring(datestring, 12, 13))
  min <- as.numeric(substring(datestring, 14, 15))
  sec <- as.numeric(substring(datestring, 16, 17))
  ISOdatetime(year, month, day, hr, min, sec, tz = "UTC")
}

#' Read all monthly output files in a directory
#'
#' @param outdir Directory to scan for files
#' @param save_file Name of file for saving output. Defualt is
#'   `file.path(outdir, "monthly-output.rds")`
#' @param force Logical. If `TRUE`, ignore saved file and re-read. If `FALSE`
#'   (default), read cached output if it exists, or load output otherwise.
#' @return Nested `tibble` with each kind of data returned by [read_monthly_file]
#' @export
read_monthly_dir <- function(outdir,
                             save_file = file.path(outdir, "monthly-output.rds"),
                             force = FALSE) {
  if (!force && file.exists(save_file)) {
    message("Loading cached output")
    result_dfs <- readRDS(save_file)
    return(result_dfs)
  }
  message("Reading all HDF5 files")
  efiles <- list.files(outdir, pattern = ".*-E-[[:digit:]]{4}-.*\\.h5$",
                       full.names = TRUE)
  if (requireNamespace("furrr", quietly = TRUE)) {
    mapfun <- purrr::partial(furrr::future_map, .progress = TRUE)
  } else {
    warning("Package `furrr` is not installed. Reading files sequentially.")
    mapfun <- purrr::map
  }
  e_data_list <- mapfun(efiles, read_monthly_file)

  result_dfs <- tibble::tibble(
    basename = basename(outdir),
    df_scalar = list(purrr::map_dfr(e_data_list, "scalar")),
    df_cohort = list(purrr::map_dfr(e_data_list, "cohort")),
    df_soil = list(purrr::map_dfr(e_data_list, "soil")),
    df_pft = list(purrr::map_dfr(e_data_list, "pft")),
    outdir = outdir
  )
  if (!is.null(save_file)) saveRDS(result_dfs, save_file)
  result_dfs
}

#' Wrapper around `ncdf4::ncvar_get` that converts errors and messages to warnings
ncget <- function(nc, varid, ...) {
  tryCatch({
    txt <- capture.output(r <- ncdf4::ncvar_get(nc = nc, varid = varid, ...),
                          type = "output")
    if (!is.null(txt)) {
      warning("Possible problem with variable ", varid, ": ", txt)
    }
    r
  }, error = function(e) {
    warning(conditionMessage(e))
    NULL
  })
}
