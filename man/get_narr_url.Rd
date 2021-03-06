% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/download-narr.R
\name{get_narr_url}
\alias{get_narr_url}
\title{Retrieve NARR data from a given URL}
\usage{
get_narr_url(url, xy, datatype, cachefile, pb = NULL)
}
\arguments{
\item{url}{Full URL to NARR thredds file}

\item{xy}{Vector length 2 containing NARR coordinates}

\item{datatype}{Type of NARR file -- either \code{flx} or \code{sfc}}

\item{cachefile}{Output file for caching results}

\item{pb}{Progress bar R6 object (default = \code{NULL})}
}
\description{
Retrieve NARR data from a given URL
}
\author{
Alexey Shiklomanov
}
