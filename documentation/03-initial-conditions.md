Vegetation initial conditions for ED2
================
Alexey Shiklomanov

Relevant ED2IN settings:

  - `RUNTYPE` – This should be set to `'INITIAL'`, which indicates that
    ED2 will initialize most biophysical quantities itself (as opposed
    to `HISTORY`, which is used to resume previous runs – in that case,
    ED2 will inherit as much as it can from the previous run).
  - `IED_INIT_MODE` – How plant community and soil carbon pools are
    initialized. Has many different possibilities, which are described
    in the ED2IN file and the [ED2
    wiki](https://github.com/EDmodel/ED2/wiki/Initial-conditions). For
    the purposes of this document, use `IED_INIT_MODE = 6`, which means
    that we *will* provide patch and cohort information, but not site
    information (`IED_INIT_MODE = 3` is the same, but *does* include
    site information).
  - `SFILIN` – Path and prefix where to look for initial condition
    files. Site latitude and longitude, along with the file extension
    (`.css` for cohort files, `.pss` for patch files, and `.site` for
    site files), will be appended to this during the search. So, for
    example, `SFILIN =
    'unsynced-data/ed2-input-files/initial-conditions/myinit'` combined
    with `IED_INIT_MODE = 3` and site coordinates `POI_LAT = 45.5625`
    and `POI_LON = -84.6975` will make ED2 look for files
    `unsynced-data/ed2-input-files/initial-conditions/myinit.lat45.5625lon-84.6975.css`
    and `.../myinit.lat45.5625lon-84.6975.pss`. The `ed4forte` helper
    function `coords_prefix()` will convert a prefix, file extension,
    and coordinates (with UMBS coordinates as defaults) into the correct
    file name.

<!-- end list -->

``` r
# UMBS coordinates are included as defaults
coords_prefix("path/to/prefix", "css")
#> [1] "path/to/prefix.lat45.5625lon-84.6975.css"
```

The cohort (`css`) and patch (`pss`) files are both space-delimited
files. Their format is described in detail in the [ED2
wiki](https://github.com/EDmodel/ED2/wiki/Initial-conditions), but
briefly: The `css` file contains one row per cohort and describes (among
other things) their size (diameter at breast height, `dbh`, in cm), stem
density (`n`, in plants per m\(^2\)), and which patch they belong to.
The `pss` file contains one row per patch, and describes, among other
things, the patch’s area (as a fraction of the total site area, so 0-1)
and age (in years since last disturbance).

Both of these files can be quickly generated from the inventory data
distributed with
[`fortedata`](https://github.com/FoRTExperiment/fortedata) with the
`ed4forte` function `fortedata2ed`. For example, code like the following
can be used to quickly run ED2 initialized from FoRTE inventory data:

``` r
# devtools::install_github("FoRTExperiment/fortedata")
library(ed4forte)
narr_ed <- here::here("unsynced-data", "ed-input-data", "NARR-ED2",
                      "ED_MET_DRIVER_HEADER")
outdir <- here::here("unsynced-data", "ed2-outputs", "forte-inits")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

prefix <- file.path(outdir, "fortedata")
css_pss <- fortedata2ed(output_prefix = prefix)
```

``` r
p <- run_ed2(
  # NOTE: 4.5 year simulation -- could take a few minutes...
  outdir, "2000-06-01", "2005-01-01",
  ED_MET_DRIVER_DB = narr_ed,
  IED_INIT_MODE = 6,
  # Only include North pine (6), late conifer (8), and early (9), mid (10), and
  # late (11) temperate hardwoods.
  INCLUDE_THESE_PFT = c(6, 8:11),
  SFILIN = prefix
)
get_status(p)
p$wait()
```

Note that because this run features multiple patches, the logic in
`read_monthly_dir` for binding these together will not work, so we will
have to pull out and combine variables by hand. The somewhat janky code
below does this.

``` r
getvar <- function(f, v) {
  nc <- ncdf4::nc_open(f)
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  ncdf4::ncvar_get(nc, v)
}
files <- list.files(outdir, "analysis-E", full.names = TRUE)

dat <- tibble::tibble(
  dates = stringr::str_extract(files, "[[:digit:]]{4}-[[:digit:]]{2}") %>%
    paste0("-01") %>%
    as.Date(),
  hite = lapply(files, getvar, "HITE"),
  dbh = lapply(files, getvar, "DBH"),
  pft = lapply(files, getvar, "PFT")
)

library(ggplot2)
dat %>%
  tidyr::unnest(c(hite, dbh, pft)) %>%
  # Structure doesn't change that often. Let's look at July of every year.
  dplyr::filter(lubridate::month(dates) == 7) %>%
  dplyr::group_by(dates) %>%
  dplyr::mutate(icohort = dplyr::row_number()) %>%
  dplyr::ungroup() %>%
  ggplot() +
  aes(x = icohort, xend = icohort, yend = 0, y = hite, size = dbh, color = factor(pft)) +
  geom_segment(size = 1) +
  geom_point() +
  facet_wrap(vars(dates)) +
  scale_color_brewer(palette = "Set1") +
  theme(axis.text.x = element_blank()) +
  ggtitle("Height and DBH, by cohort and PFT, for five ED2 simulation years.")
```

![](03-initial-conditions_files/figure-gfm/read-outputs-1.png)<!-- -->

In this plot, we can start to see how ED2 works. Both the total number
of cohorts, and the number of patches (groups of cohorts), changes over
the course of the run, as ED2 fuses similar cohorts and patches when
there are too many (see `ED2IN` variables `MAXCOHORTS` and `MAXPATCHES`)
or splits them when there are relatively few. Also, we can see
recruitment of new seedlings – even over the course of 5 years, some
small new trees of different PFTs appear in the understory.
