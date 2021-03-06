% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download-narr.R
\name{generate_narr_url}
\alias{generate_narr_url}
\title{Generate NARR url from a vector of dates}
\usage{
generate_narr_url(dates, datatype)
}
\arguments{
\item{dates}{Vector of dates for which to generate URL}

\item{datatype}{Type of NARR file -- either \code{flx} or \code{sfc}}
}
\description{
Figures out file names for the given dates, based on NARR's convoluted and
inconsistent naming scheme.
}
\author{
Alexey Shiklomanov
}
