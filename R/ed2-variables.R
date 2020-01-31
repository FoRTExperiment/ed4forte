#' ED2 output variable table
#'
#' Table of variable information extracted from the ED2 source code
#' (`ed_state_vars.f90`).
#'
#' Columns in the output are as follows:
#'
#' - `variable` -- The variable name as it appears in the HDF5 output
#' - `description` -- Variable description
#' - `unit` -- Variable unit. `NA` indicuates unitless quantities. Some units
#' are unspecified.
#' - `dimensions` -- What dimensions the variable has in the output. For
#' instance, `(n_pft,n_dbh,ipoly)` means the variable is stored in an array with
#' one row (first dimension) per PFT, one column (second dimension) per DBH
#' class, and polygons in the third dimension. Dimension value codes are as
#' follows:
#'     - `ipoly` -- Number of polygons. For site-level runs, should be 1.
#'     - `ipatch` -- Number of patches. Typically 1, unless multiple patches
#'     have been specified.
#'     - `icohort` -- Number of cohorts. Changes on a monthly timestep.
#'     - `ndcycle` -- Number of steps in the diurnal cycle output. See output
#'     variable `NDCYCLE` as well as `IQOUTPUT` documentation in the ED2IN file.
#'     - `n_pft` -- Number of plant functional types (PFTs). Should be
#'     hard-coded to 17. See the `INCLUDE_THESE_PFT` table in the ED2IN file for
#'     (defualt) PFT definitions.
#'     - `n_dbh` -- Number of DBH classes, in 10cm increments (11 values total).
#'     First value is for all plants with DBH <= 10cm, second value is 10 < DBH
#'     <= 20, third value is 20 < DBH <= 30, etc., and the last value is DBH >
#'     100cm.
#'     - `nzg` -- Number of soil levels. Defined by the `NZG` variable in ED2IN
#'     (and in the output).
#'     - `n_hgt_class` -- Number of height classes. If ED2IN flag IFUSION is 0
#'     (default) then 8; otherwise, 19.
#'     - `iradprof` -- Radiation profile identifiers. Hard coded to 10, with
#'     values corresponding to the following (PAR is "photosynthetically active
#'     radiation", ~400-700nm wavelength; NIR is "near-infrared", ~700-2500nm
#'     wavelength. "Beam" is direct radiation. Thermal radiation is diffuse by
#'     definition):
#'         - 1: PAR, Beam, Down
#'         - 2: PAR, Beam, Up
#'         - 3: PAR, Diffuse, Down
#'         - 4: PAR, Diffuse, Up
#'         - 5: NIR, Beam, Down
#'         - 6: NIR, Beam, Down
#'         - 7: NIR, Diffuse, Down
#'         - 8: NIR, Diffuse, Up
#'         - 9: Thermal, Down
#'         - 10: Thermal, Up
#'     - A number (e.g. `5`) -- The hard-coded literal dimension size.
#'     - `NA` (no dimension) indicates a scalar quantity (length = 1)
#' - `code_variable` -- The variable name used in the ED2 source code
#' - `in_<*>` -- Whether or not the variable is included in the corresponding
#' output file (unless noted otherwise, the file letter code corresponds to the
#' second letter in the ED2IN output type, so, for instance, `ISOUTPUT` produces
#' files with the `-S-` identifier):
#'     - `history` -- History restart files. ED2IN tag `ISOUTPUT`.
#'     - `analysis` -- Instantaneous output ("fast analysis") files, one per
#'     time step. ED2IN tags `IFOUTPUT` and `IOOUTPUT`.
#'     - `daily` -- Daily averages. ED2IN tag `IDOUTPUT`.
#'     - `monthly` -- Monthly averages. ED2IN tag `IMOUTPUT`. File tag `-E-`.
#'     - `diurnal` -- Monthly averages of the diurnal cycle. ED2IN tag `IQOUTPUT`.
#'     - `yearly` -- Yearly averages. ED2IN tag `IYOUTPUT`.
#'     - `tower` -- "Tower" files; fast output, but aggregated to one file per
#'     year.
#' - `glob_id` -- Not sure, but might be useful?
#' - `info_string` -- The raw file information string from which the variable
#' name and output file was derived. Mostly for debugging.
#'
#' @param variables Optional character vector of parameters to query
#' @return `data.frame` of ED2 variable information. See "Details".
#' @author Alexey Shiklomanov
#' @export
ed2_variable_info <- function(variables = NULL) {
  result <- readr::read_csv(
    system.file("ed2-state-variables.csv", package = "ed4forte"),
    cols = readr::cols(variable = "c", description = "c", unit = "c",
                       dimensions = "c", code_variable = "c",
                       in_history = "l", in_analysis = "l", in_daily = "l",
                       in_monthly = "l", in_diurnal = "l", in_yearly = "l",
                       in_tower = "l", glob_id = "c", info_string = "c")
  )
  if (!is.null(variables)) {
    result <- dplyr::filter(result, variable %in% variables)
    missing_vars <- setdiff(variables, result$variable)
    if (length(missing_vars)) {
      warning("The following variables not found in ED2 variables table: ",
              paste(missing_vars, collapse = ", "))
    }
  }
  result
}
