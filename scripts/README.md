# Helper scripts for ED2-related tasks

- `download-NARR-met.R`: Download North American Regional Reanalysis (NARR) meteorology for UMBS. Stores the NARR CF-format files in `unsynced-data/narr` (one NetCDF file per year). Then, converts these files to ED2 format (HDF5, one file per month) and stores them in `unsynced-data/narr-ed`.
    - NOTE: The conversion to ED2 format uses functions from [PEcAn](https://github.com/pecanproject/pecan), which currently have a _lot_ of dependencies. We're working on this...
