ED 2.2 R interface
================
Alexey Shikloamnov

# Prepare inputs

For this tutorial, in your working directory, create a folder called
`ed-input-data`.

Download meteorology inputs from the [GitHub releases
page](https://github.com/FoRTExperiment/ed4forte/releases/tag/met-ed2).
For this tutorial, use the `NARR-ED2.tar.gz` file (North American
Regional Reanalysis). Download the file into `ed-input-data` and extract
it.

``` sh
cd ed-input-data
tar -xf NARR-ED2.tar.gz
cd ..
```

You should now have a directory `ed-input-data/NARR-ED2` containing a
bunch of files like `1979JAN.h5` as well as a file called
`ED_MET_DRIVER_HEADER`.

Open the `ed-input-data/NARR-ED2/ED_MET_DRIVER_HEADER` file in a text
editor, and change the third line (`/Users/shik544/...`) so it matches
the path of the directory
(e.g. `/path/to/current/directory/ed-input-data/NARR-ED2/`). You can
also do this with the following shell command:

``` sh
# Use `gsed` instead of `sed` if on MacOS
sed -i "3s:.*:$PWD/ed-input-data/NARR-ED2/:" ed-input-data/NARR-ED2/ED_MET_DRIVER_DATA
```

The remaining inputs required for a basic ED2 simulation ship with the
`ed4forte` package. Install the package from your local clone
(`devtools::install("/path/to/ed4forte")`) or from GitHub
(`devtools::install_github("FoRTExperiment/ed4forte")`).

# Basic ED2 run

First, locate the ED2 executable and set the R option `ed4forte.ed2_exe`
to the absolute path to this executable.

``` r
options(ed4forte.ed2_exe = "/path/to/ED/build/ed_2.2-dbg")
```

Use the following R code to perform a simple ED2 simulation at UMBS for
the year 2000 starting from bare ground:

``` r
library(ed4forte)

outdir <- "test-ed-outputs"
ed_input_dir <- "ed-input-data"

p <- run_ed2(
  outdir,
  "2000-01-01",
  "2001-01-01",
  ED_MET_DRIVER_DB = file.path(ed_input_dir, "NARR-ED2", "ED_MET_DRIVER_HEADER")
)
```

The first argument to `run_ed2` is the output directory (which will be
created if it doesn’t exist). The next two arguments are the start and
end date (-times), respectively. The last argument indicates that the
default ED2IN value of the `ED_MET_DRIVER_DB` tag should be modified to
that value. Any default values for ED2IN tags can be modified in this
way.

Note that the code above will return immediately. This is because it
triggers ED2 to run in the background. The return object (`p`) is a
[`processx`](https://processx.r-lib.org/index.html) process, which can
be examined.

``` r
p$get_status()
```

    ## [1] "running"

``` r
p$is_alive()
```

    ## [1] TRUE

For more details, see the [`processx::process`
documentation](https://processx.r-lib.org/reference/process.html). To
wait for the run to complete, use the `wait()` method.

``` r
p$wait()
```

You can tell that the run finished by examining the contents of the
output directory.

``` r
list.files(outdir)
```

    ##  [1] "analysis-E-2000-01-00-000000-g01.h5" "analysis-E-2000-02-00-000000-g01.h5" "analysis-E-2000-03-00-000000-g01.h5" "analysis-E-2000-04-00-000000-g01.h5" "analysis-E-2000-05-00-000000-g01.h5" "analysis-E-2000-06-00-000000-g01.h5"
    ##  [7] "analysis-E-2000-07-00-000000-g01.h5" "analysis-E-2000-08-00-000000-g01.h5" "analysis-E-2000-09-00-000000-g01.h5" "analysis-E-2000-10-00-000000-g01.h5" "analysis-E-2000-11-00-000000-g01.h5" "analysis-E-2000-12-00-000000-g01.h5"
    ## [13] "ED2IN"                               "stderr.log"                          "stdout.log"

You should see the 12 monthly output files, along with a copy of the
ED2IN file used for the run and two log files corresponding to the input
(`stdout`) and error (`stderr`) streams.
