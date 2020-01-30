#' Run ED2
#'
#' This uses the `processx` package to create an ED2 process that runs in the
#' background. This allows you to do other things while ED2 is running.
#'
#' @param outdir Output directory
#' @inheritParams processx::process
#' @return A [processx::process()] object corresponding to the running ED2
#'   process.
#' @author Alexey Shiklomanov
#' @export
run_ed2 <- function(outdir,
                    ed2_exe = getOption("ed4forte.ed2_exe"),
                    wd = NULL,
                    env = NULL,
                    stdout = file.path(outdir, "stdout.log"),
                    stderr = file.path(outdir, "stderr.log"),
                    ...) {
  stopifnot(file.exists(ed2_exe))
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  settings <- ed2in(
    !!!rlang::list2(...),
    FFILOUT = file.path(outdir, "analysis"),
    SFILOUT = file.path(outdir, "history")
  )
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
