#' Read an ED2IN file to a list
#'
#' Knows how to handle strings, numbers, and vectors thereof.
#'
#' @inheritParams base::readLines
#' @param ... Additional arguments
#' @return Named list of tags and values.
#' @author Alexey Shiklomanov
#' @export
read_ed2in <- function(con, ...) {
  raw_file <- readLines(con = con, ...)
  # Remove all comments
  nocomment <- gsub("!+.*", "", trimws(raw_file))
  # Remove blank lines
  procfile <- trimws(nocomment[nocomment != ""])

  # Extract tag-value pairs
  ed2in_tag_rxp <- paste0(
    "NL%([[:graph:]]+)",          # Capture namelist tag (1)
    "[[:blank:]]+=[[:blank:]]*",  # Equals, with optional surrounding whitespace
    "(",                          # Begin value capture (2)
    "[[:digit:].-]+(,[[:blank:]]*[[:digit:].-]+)*",   # Number, or number list
    "|",                          # ...or...
    "@.*?@",                      # Old substitution tag (e.g. @MYVALUE@)
    "|",                          # ...or...
    "'[[:graph:][:blank:]]*'",    # Quoted string, or list of strings
    ")",                          # End value capture
    "[[:blank:]]*!?.*$"           # Trailing whitespace and possible comments
  )

  taglines <- grep("NL%", procfile, value = TRUE)
  tags <- gsub(ed2in_tag_rxp, "\\1", taglines, perl = TRUE)
  values <- gsub(ed2in_tag_rxp, "\\2", taglines, perl = TRUE)

  # Convert to a list to allow storing of multiple data types
  values_list <- as.list(values)

  numeric_values <- !is.na(suppressWarnings(as.numeric(values))) |
    grepl("^@.*?@$", values)    # Unquoted old substitutions are numeric
  values_list[numeric_values] <- lapply(values_list[numeric_values], as.numeric)
  # This should throw a warning if any old substitution tags are present

  # Convert values that are a list of numbers to a numeric vector
  numlist_values <- grep(
    "[[:digit:].-]+(,[[:blank:]]*[[:digit:].-]+)+",
    values
  )
  values_list[numlist_values] <- lapply(
    values_list[numlist_values],
    function(x) as.numeric(strsplit(x, split = ",")[[1]])
  )

  # Convert values that are a list of strings to a character vector
  charlist_values <- grep("'.*?'(,'.*?')+", values)
  values_list[charlist_values] <- lapply(
    values_list[charlist_values],
    function(x) strsplit(x, split = ",")[[1]]
  )

  # Remove extra quoting of strings
  quoted_values <- grep("'.*?'", values)
  values_list[quoted_values] <- lapply(
    values_list[quoted_values],
    gsub,
    pattern = "'",
    replacement = ""
  )

  names(values_list) <- tags

  values_list
}

#' Write ED2IN list to file
#'
#' @param ed2in Named list of ED2IN tags (`tag = value`)
#' @param ... Additional arguments to [base::writeLines]
#' @inherit base::writeLines return params
#' @export
write_ed2in <- function(ed2in, con, ...) {
  writeLines(
    c("$ED_NL", tags2char(ed2in), "$END"),
    con = con,
    ...
  )
  invisible(con)
}

#' Create (and optionally modify) an ED2IN list based on the default provided in
#' this package
#'
#' @param ... Name-value pairs of ED2IN tags to modify. Supports quasiquotation
#'   through [rlang::list2()].
#' @inherit read_ed2in return
#' @export
ed2in <- function(...) {
  mods <- rlang::list2(...)
  filename <- system.file("ED2IN", package = "ed4forte")
  common_input_dir <- system.file("ed-inputs-common", package = "ed4forte")
  base_ed2in <- modifyList(read_ed2in(filename), list(
    THSUMS_DATABASE = file.path(common_input_dir, "chd-dgd/"),
    VEG_DATABASE = file.path(common_input_dir, "veg-oge", "OGE2_")
  ))
  modifyList(base_ed2in, mods)
}

#' Format ED2IN tag-value list
#'
#' Converts an `ed2in`-like list to an ED2IN-formatted character vector.
#'
#' @inheritParams write_ed2in
tags2char <- function(ed2in) {
  char_values <- vapply(ed2in, is.character, logical(1))
  na_values <- vapply(ed2in, function(x) all(is.na(x)), logical(1))
  quoted_vals <- ed2in
  quoted_vals[char_values] <- lapply(quoted_vals[char_values], shQuote)
  quoted_vals[na_values] <- lapply(quoted_vals[na_values], function(x) "")
  values_vec <- vapply(quoted_vals, paste, character(1), collapse = ",")
  tags_values_vec <- sprintf("   NL%%%s = %s", names(values_vec), values_vec)
  tags_values_vec
}
