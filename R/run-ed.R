#' Run ED2
#'
#' This uses the `processx` package to create an ED2 process that runs in the
#' background. This allows you to do other things while ED2 is running.
#'
#' @param outdir Output directory
#' @param start_dt,end_dt Start and end date-times of simulation. Can be given
#'   as POSIX(ct/lt), or character (in which case, they will be converted via
#'   [base::as.POSIXct()]).
#' @param configxml A `list` (or `data.frame`) of parameter values (see
#'   [write_configxml()]) or the path to a configuration XML file.
#' @param wd Process working directory (default, `NULL`, means current working
#'   directory). See [processx::process].
#' @param env Process environment variables (default, `NULL`, means inherit
#'   current environment). See [processx::process].
#' @inheritParams base::as.POSIXct
#' @return A [processx::process()] object corresponding to the running ED2
#'   process.
#' @author Alexey Shiklomanov
#' @export
run_ed2 <- function(outdir, start_dt, end_dt,
                    configxml = NULL,
                    ed2_exe = getOption("ed4forte.ed2_exe"),
                    wd = NULL,
                    env = NULL,
                    stdout = file.path(outdir, "stdout.log"),
                    stderr = file.path(outdir, "stderr.log"),
                    tz = "UTC",
                    ...) {
  stopifnot(!is.null(ed2_exe), file.exists(ed2_exe))
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  if (!inherits(start_dt, "POSIX")) start_dt <- as.POSIXct(start_dt, tz = tz)
  if (!inherits(end_dt, "POSIX")) end_dt <- as.POSIXct(end_dt, tz = tz)

  ed2in_default <- list(
    # Start date
    IYEARA = as.numeric(format(start_dt, "%Y")),
    IMONTHA = as.numeric(format(start_dt, "%m")),
    IDATEA = as.numeric(format(start_dt, "%d")),
    ITIMEA = as.numeric(format(start_dt, "%H")),
    # End date
    IYEARZ = as.numeric(format(end_dt, "%Y")),
    IMONTHZ = as.numeric(format(end_dt, "%m")),
    IDATEZ = as.numeric(format(end_dt, "%d")),
    ITIMEZ = as.numeric(format(end_dt, "%H")),
    # Output files
    FFILOUT = file.path(outdir, "analysis"),
    SFILOUT = file.path(outdir, "history")
  )

  configfile <- NULL
  if (!is.null(configxml)) {
    if (is.character(configxml)) {
      stopifnot(file.exists(configxml))
      configfile <- configxml
    } else if (is.list(configxml)) {
      configfile <- file.path(outdir, "config.xml")
      write_configxml(configxml, configfile)
    }
  }

  if (!is.null(configfile)) {
    ed2in_default[["IEDCNFGF"]] <- configfile
  }

  ed2in_args <- modifyList(ed2in_default, rlang::list2(...))

  settings <- ed2in(!!!ed2in_args)

  settings_file <- file.path(outdir, "ED2IN")
  write_ed2in(settings, settings_file)
  processx::process$new(
    ed2_exe,
    c("-f", settings_file),
    wd = wd,
    stdout = stdout,
    stderr = stderr
    ## post_process = function() read_efile_dir(outdir)
  )
}
