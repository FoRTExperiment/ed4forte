#' Run ED2
#'
#' @param outdir Output directory
#' @return Output directory, invisibly
#' @author Alexey Shiklomanov
#' @export
run_ed2 <- function(outdir, ...) {
  ed2_exe <- here::here("ed2")
  stopifnot(file.exists(ed2_exe))
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  settings <- ed2in(
    !!!rlang::list2(...),
    FFILOUT = file.path(outdir, "analysis"),
    SFILOUT = file.path(outdir, "history")
  )
  settings_file <- file.path(outdir, "ED2IN")
  write_ed2in(settings, settings_file)
  system2(ed2_exe, c("-f", settings_file))
  invisible(outdir)
}
