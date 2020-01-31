#' Read ED2 parameter file (`config.xml`) into a `data.frame`
#'
#' @param filename Path and filename of configuration file
#' @return Wide `data.frame` containing parameters for each PFT.
#' @importFrom magrittr "%>%"
#' @export
read_configxml <- function(filename) {
  stopifnot(file.exists(filename))
  xml <- xml2::read_xml(filename) %>%
    xml2::as_list()
  xml[["config"]] %>%
    purrr::map_dfr(tibble::as_tibble) %>%
    dplyr::mutate_all(purrr::simplify) %>%
    ## Missing parameters are set to `NULL`, which `simplify` can't
    ## handle. Convert to NA and then re-simplify only those columns.
    dplyr::mutate_if(is.list, ~purrr::map_if(.x, is.null, ~NA_character_)) %>%
    dplyr::mutate_if(is.list, purrr::simplify) %>%
    dplyr::mutate_all(readr::parse_guess)
}

#' Prepare ED2 parameter config file from a parameter list
#'
#' @param param_list Nested list of parameter values, or a `data.frame` with one
#'   row per PFT and parameters in columns (which will be converted to a list
#'   with [purrr::transpose()]).
#' @param filename Name of file to write to. Default (`NULL`) means don't write
#'   to file.
#' @return In-memory `xml2` document representing the file (invisibly)
#' @author Alexey Shiklomanov
#' @export
#' @examples
#' l <- list(pft = list(num = 9, sla = 22), pft = list(num = 10, sla = 30))
#' write_configxml(l, tempfile())
#'
#' # If list has no names, assume that each element is a PFT
#' # So, below command is identical to above.
#' l2 <- list(list(num = 9, sla = 22), list(num = 10, sla = 30))
#' write_configxml(l2, tempfile())
#'
#' # Can also set non-PFT parameters this way
#' l3 <- list(
#'   pft = list(num = 9, sla = 22),
#'   pft = list(num = 10, sla = 30),
#'   phenology = list(retained_carbon_fraction = 0.5, theta_crit = 0.3)
#' )
#' write_configxml(l3, tempfile())
#'
#' # data.frames are converted to lists with `purrr::transpose()`
#' df1 <- data.frame(num = c(9, 10), sla = c(22, 30))
#' write_configxml(df1, tempfile())
write_configxml <- function(param_list, filename = NULL) {
  if (is.data.frame(param_list)) {
    param_list <- purrr::transpose(param_list)
  }
  if (is.null(names(param_list))) {
    names(param_list) <- rep("pft", length(param_list))
  }
  # Every PFT needs a `num`
  pft_params <- param_list[names(param_list) == "pft"]
  stopifnot(all(purrr::map_lgl(pft_params, rlang::has_name, "num")))
  xml <- xml2::xml_new_root("config")
  nodes <- lapply(names(param_list), xml2::xml_add_child, .x = xml)
  Map(set_child_values, nodes, param_list)
  if (!is.null(filename)) {
    xml2::write_xml(xml, filename)
  }
  invisible(xml)
}

set_child_values <- function(.x, .l) {
  nodes <- lapply(names(.l), xml2::xml_add_child, .x = .x)
  # XML text has to be character
  out <- Map(xml2::xml_set_text, x = nodes, value = lapply(.l, as.character))
  invisible(out)
}
