---
title: "Vegetation initial conditions for ED2"
author: "Alexey Shiklomanov"
---

Relevant ED2IN settings:

- `RUNTYPE` -- This should be set to `'INITIAL'`, which indicates that ED2 will initialize most biophysical quantities itself
(as opposed to `HISTORY`, which is used to resume previous runs -- in that case, ED2 will inherit as much as it can from the previous run).
- `IED_INIT_MODE` -- How plant community and soil carbon pools are initialized.
Has many different possibilities, which are described in the ED2IN file and the [ED2 wiki][ed2-ini-wiki].
For the purposes of this document, use `IED_INIT_MODE = 6`, which means that we _will_ provide patch and cohort information, but not site information (`IED_INIT_MODE = 3` is the same, but _does_ include site information).
- `SFILIN` -- Path and prefix where to look for initial condition files.
Site latitude and longitude, along with the file extension (`.css` for cohort files, `.pss` for patch files, and `.site` for site files), will be appended to this during the search.
So, for example, `SFILIN = 'unsynced-data/ed2-input-files/initial-conditions/myinit'` combined with `IED_INIT_MODE = 3` and site coordinates `POI_LAT = 45.5625` and `POI_LON = -84.6975` will make ED2 look for files `unsynced-data/ed2-input-files/initial-conditions/myinit.lat45.5625lon-84.6975.css` and `.../myinit.lat45.5625lon-84.6975.pss`.
The `ed4forte` helper function `coords_prefix()` will convert a prefix, file extension, and coordinates (with UMBS coordinates as defaults) into the correct file name.

``` r
# UMBS coordinates are included as defaults
coords_prefix("path/to/prefix", "css")
#> [1] "path/to/prefix.lat45.5625lon-84.6975.css"
```

The cohort (`css`) and patch (`pss`) files are both space-delimited files.
Their format is described in detail in the [ED2 wiki][ed2-ini-wiki], but briefly:
The `css` file contains one row per cohort and describes (among other things) their size (diameter at breast height, `dbh`, in cm), stem density (`n`, in plants per m$^2$), and which patch they belong to.
The `pss` file contains one row per patch, and describes, among other things, the patch's area (as a fraction of the total site area, so 0-1) and age (in years since last disturbance).

Both of these files can be quickly generated from the inventory data distributed with [`fortedata`][fortedata] with the `ed4forte` function `fortedata2ed`.

[ed2-ini-wiki]: https://github.com/EDmodel/ED2/wiki/Initial-conditions
[fortedata]: https://github.com/FoRTExperiment/fortedata
