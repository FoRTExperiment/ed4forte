#' ED2 output variable list
#'
#' @param variables Optional character vector of parameters to query
#' @return `data.frame` of ED2 variable information
#' @author Alexey Shiklomanov
#' @export
ed2_variable_info <- function(variables = NULL) {
  result <- ed2_variables
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
