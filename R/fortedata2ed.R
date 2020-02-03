#' Create ED2 vegetation initial condition files from `fortedata` inventory files
#'
#' @param inventory Inventory data. Default is [fortedata::fd_inventory()]
#' @param subplots Subplot information. Default is [fortedata::fd_subplots()]
#' @param output_prefix Output prefix to which to write files. If `NULL`
#'   (default), do not write files.
#' @return (Invisibly) List containing cohort (`css`) and patch (`pss`) `tibble`s
#' @author Alexey Shiklomanov
#' @export
fortedata2ed <- function(inventory = fortedata::fd_inventory(),
                         subplots = fortedata::fd_subplots(),
                         output_prefix = NULL) {
  # TODO: Disturbance type -- 3 == "Burned".
  if (!"trk" %in% colnames(subplots)) subplots[["trk"]] <- 3
  if (!"age" %in% colnames(subplots)) subplots[["age"]] <- 100
  if (!"area" %in% colnames(subplots)) {
    subplots[["area"]] <- with(subplots, Subplot_area_m2 / sum(Subplot_area_m2)) #nolint
  }
  if (!"patch" %in% colnames(subplots)) {
    subplots[["patch"]] <- with(subplots, paste(
      Plot, Subplot, Replicate, sep = "-"
    ))
  }

  pss_cols <- c("time", "patch", "trk", "age", "area",
                "water", "fsc", "stsc", "stsl", "ssc",
                "lai", "msn", "fsn")
  pss_default <- tibble::tibble(
    time = -999, water = -999, lai = -999,
    fsc = 0.46, stsc = 3.9, stsl = 3.9,
    ssc = 0.003, msn = 1, fsn = 1
  )

  css_cols <- c("time", "patch", "cohort", "dbh",
                "hite", "pft", "n", "bdead", "balive", "lai")
  css_default <- tibble::tibble(
    time = -999, hite = -999,
    bdead = -999, balive = -999, lai = -999
  )

  patches <- subplots %>%
    dplyr::mutate(
      !!!pss_default[, setdiff(colnames(pss_default), colnames(.))]
    ) %>%
    dplyr::select(!!pss_cols, dplyr::everything())

  css <- inventory %>%
    dplyr::inner_join(patches, c("Replicate", "Plot", "Subplot")) %>%
    # Inner join here to exclude unmatched species
    dplyr::inner_join(species_pfts(), "Species") %>%
    dplyr::mutate(
      cohort = dplyr::row_number(),
      n = 1 / Subplot_area_m2,
      !!!css_default[, setdiff(colnames(css_default), colnames(.))]
    ) %>%
    dplyr::rename(dbh = DBH_cm) %>%
    dplyr::select(!!css_cols)
  pss <- patches %>% dplyr::select(!!pss_cols)

  if (!is.null(output_prefix)) {
    dir.create(dirname(output_prefix), showWarnings = FALSE, recursive = TRUE)
    readr::write_delim(css, coords_prefix(output_prefix, "css"), delim = " ")
    readr::write_delim(pss, coords_prefix(output_prefix, "pss"), delim = " ")
  }

  invisible(list(css = css, pss = pss))
}
