library(magrittr)
stopifnot(
  requireNamespace("here", quietly = TRUE),
  requireNamespace("xml2", quietly = TRUE),
  requireNamespace("tibble", quietly = TRUE),
  requireNamespace("purrr", quietly = TRUE),
  requireNamespace("tidyr", quietly = TRUE),
  requireNamespace("readr", quietly = TRUE)
)
devtools::load_all(here::here())

# Do a really quick ED2 run, just to generate the history.xml file
narr_met <- here::here("unsynced-data", "ed-input-data", "NARR-ED2",
                       "ED_MET_DRIVER_HEADER")
outdir <- tempfile()
dir.create(outdir)
p <- run_ed2(
  outdir,
  "1980-01-01", "1980-01-05",
  configxml = data.frame(num = c(9, 10, 11), is_tropical = 0),
  ED_MET_DRIVER_DB = narr_met,
  INCLUDE_THESE_PFT = 1:17
)
p$wait()

histxml <- file.path(outdir, "history.xml")
x <- xml2::read_xml(histxml)
xl <- xml2::as_list(x)[["config"]]

file.copy(histxml, here::here("inst", "ed2-default-parameters.xml"))

xdf <- tibble::tibble(
  type = names(xl),
  values = purrr::map(xl, tibble::as_tibble)
)

simplify_xml <- function(x) {
  x %>%
    purrr::simplify() %>%
    trimws() %>%
    readr::parse_guess()
}

pft_dat <- xdf %>%
  dplyr::filter(type == "pft") %>%
  tidyr::unnest(values) %>%
  dplyr::mutate_all(simplify_xml) %>%
  tidyr::pivot_longer(
    -c(type, num),
    names_to = "parameter",
    values_to = "value"
  )

pft_dat %>%
  dplyr::select(num, parameter, value) %>%
  tidyr::pivot_wider(names_from = "parameter", values_from = "value") %>%
  readr::write_csv(here::here("inst", "ed2-default-pft-parameters.csv"))
