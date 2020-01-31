read_raw_fortran <- function(string) {
  code <- trimws(string)
  code <- grep("^!", code, invert = TRUE, value = TRUE)
  code <- code[code != ""]
  code <- gsub("!.*", "", string)

  # Join continued lines (end in `&`)
  result <- character(length(code))
  i <- 1
  j <- 1
  while (i <= length(code)) {
    s <- code[i]
    while (grepl("&", s)) {
      s <- gsub("&", "", s)
      i <- i + 1
      s <- paste0(s, code[i])
    }
    result[j] <- s
    j <- j + 1
    i <- i + 1
  }
  result <- result[seq_len(j-1)]
  trimws(result[result != ""])
}
