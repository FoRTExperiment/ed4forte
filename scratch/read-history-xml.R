import::from("magrittr", "%>%")

histxml <- here::here("unsynced-data", "blank-config-quick", "history.xml")
x <- xml2::read_xml(histxml)
xl <- xml2::as_list(x)[["config"]]

xml_list2df <- function(xml_list) {
  xml_list %>%
    purrr::map_dfr(tibble::as_tibble, .name_repair = "unique") %>%
    dplyr::mutate_all(trimws) %>%
    dplyr::mutate_all(readr::parse_guess)
}

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
  readr::write_csv(here::here("inst", "ed2-pft-defaults.csv"))

other_dat <- xdf %>%
  dplyr::filter(type != "pft") %>%
  dplyr::mutate(
    values = purrr::map_depth(values, 2, simplify_xml)
  )

other_dat %>%
  tidyr::unnest(values)

xdf %>% count(type)


xdf2 <- xdf %>%
  group_split(type)



xdf3 <- purrr::map(xdf2, bind_rows)

ed2_variable_info() %>%
  filter(grepl("NPLANT", variable))

length(xdf2)
xdf2[[1]]
  summarize(values = do.call(bind_rows, values))

  purrr::map(xl, as_tibble, .id = "type")

unames <- unique(names(xl))
outlist <- purrr::map(unames, ~xml_list2df(xl[names(xl) == .]))
names(outlist) <- unames

names(outlist)
