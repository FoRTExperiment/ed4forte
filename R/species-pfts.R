
#' Conversion betwen FoRTE species and ED2 PFT numbers
#'
#' @details PFT numbers (relevant to FoRTE) are as follows:
#' - 5 -- Temperate C3 grass
#' - 6 -- Northern pine
#' - 8 -- Late-successional conifer
#' - 9 -- Early-successional hardwood
#' - 10 -- Mid-successional hardwood
#' - 11 -- Late-successional hardwood
#'
#' @return `data.frame` with columns `Species` (character) and `PFT` (double)
#' @author Alexey Shiklomanov
#' @export
species_pfts <- function() {
  readr::read_csv(
    system.file("pfts-species.csv", package = "ed4forte"),
    col_types = readr::cols(Species = "c", pft = "d")
  )
}
