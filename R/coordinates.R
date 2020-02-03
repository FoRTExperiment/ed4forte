#' UMBS coordinates
#'
#' @inheritParams base::round
#' @return
#' @export
umbs_coords <- function(digits = 4) c(lat = umbs_lat(), lon = umbs_lon())

#' @rdname umbs_coords
#' @export
umbs_lat <- function(digits = 4) round(45.5625, digits)

#' @rdname umbs_coords
#' @export
umbs_lon <- function(digits = 4) round(-84.6975, digits)

#' Format a file name with coordinates
#'
#' @param prefix File path and prefix. By default, don't need the trailing `.`
#'   because it's set by `sep`.
#' @param extension File extension. By default, don't need the leading `.`
#'   because it's set by `sep`.
#' @param coords Numeric vector of latitude (name `lat`) and longitude (name
#'   `lon`). If not named, assume `lat,lon`. Default is [umbs_coords()].
#' @param sep Separator between elements. Default = `"."`
#' @return Path with lat-lon included
#' @export
coords_prefix <- function(prefix, extension,
                          coords = umbs_coords(), sep = ".") {
  if (is.null(names(coords))) names(coords) <- c("lat", "lon")
  coord_string <- paste0("lat", coords["lat"], "lon", coords["lon"])
  paste(prefix, coord_string, extension, sep = ".")
}
