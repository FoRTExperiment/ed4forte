# Compiling ED2

## Getting the source code

Clone the source code from https://github.com/edmodel/ed2.

```sh
git clone https://github.com/edmodel/ed2
cd ed2
```

As of 2020-01-10, the big [ED-2.2 pull request](https://github.com/EDmodel/ED2/pull/289) is still in progress.
Because this is what is documented in the [Longo et al. 2019 GMD paper](https://doi.org/10.5194/gmd-2019-45), this the branch you'll probably want to use.
Switch to it:

```sh
git checkout mpaiao_pr
```

Refer to the ED2 repository README file for the general structure of the ED2 code.

## Compiling the model

Switch into the build directory.

```sh
cd ED/build
```

ED2 is installed via the `install.sh` script found in this directory.
It has the following general syntax:

```sh
./install.sh -k <kind> -p <platform> [-g] [--clean]
# E.g.
# ./install.sh -k E -p macos_homebrew -g
```

The options above are as follows:

- `<kind>` -- Either `A` for a "debug" build that compiles and runs more slowly, but has more information for debugging (the resulting executable will end in `dbg`); or `E` for an "optimized" build with a faster runtime (the resulting executable will end in `opt`). Unless you are developing ED2, you probably want `E`.
- `<platform>` -- The system on which you are compiling. This exactly corresponds to the files `ED/build/make/include.mk.<platform>`. For instance, for MacOS with libraries installed via Homebrew, use `-p macos_homebrew`, which will read variables from `ED/build/make/include.mk.macos_homebrew`. You can also create your own `include.mk.*` files, or modify existing ones, as necessary.
- `-g` -- An optional flag that disables tagging with the current Git hash. By default, the resulting binary looks something like `ed_2.2-opt-<githash>`, but with `-g`, the binary is just `ed_2.2-opt`, which is usually easier to work with.
- `--clean` -- If included, this will delete all compiled files and the binary corresponding to the installation "kind" and platform. Note that all of the other flags are required for this to work. I.e. To recompile ED2 from scratch, you'll need to run something like:
  ```sh
  # Clear the current installation
  ./install.sh -k E -p macos_homebrew -g --clean
  # Install
  ./install.sh -k E -p macos_homebrew -g
  ```

This install script will create a directory of compiled `.o` objects, a statically-compiled library (`ed_2.2-opt.a`), and the executable itself `ed_2.2-opt`.

### Special instructions for MacOS

These instructions assume you are using [Homebrew](https://brew.sh) to manage your system libraries.
Using Homebrew, install (`brew install`) the following libraries:

- `gfortran`: The GCC Fortran compiler
- `hdf5`: Libraries for HDF5 files
= `wget`: GNU Project that retrieves data from the internet

Then, compile using platform `macos_homebrew`:

```sh
./install.sh -k E -p macos_homebrew -g
```

Note that parallel execution via MPI is currently disabled on MacOS.
This means that any given ED2 simulation will on a single core.
This should only be an issue for multi-site simulations (e.g. regional runs over spatial grid); for single-site simulations, the slight overhead associated with MPI might actually make runs slightly _faster_.

### Special instructions for PIC

Running ED2 on PIC requires a precise combination of modules, as well as building one dependency by hand.

1. Unload all currently loaded modules.
   
   ```sh
   module purge
   ```
   
2. Load the specific versions of `gcc` required for ED2 to work.

   ```sh
   module load gcc/5.2.0
   ```
   
   Confirm that you have the right version of `gcc` with `gcc --version` -- make sure that it is 5.2.0.
   
   **NOTE:** ED2 needs the correct modules not only for compilation, but also to run.

3. Download and install HDF5 from source.
This is the version we will use for ED2.
It's a good idea to do all of these steps in a new directory -- I'll call it `~/custom-hdf5`.

   ```sh
   mkdir ~/custom-hdf5
   cd ~/custom-hdf5
   ```

  1. Download and extract the source code tarball and enter it.
  
      ```sh
      wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.6/src/hdf5-1.10.6.tar.gz
      tar xvf hdf5-1.10.6.tar.gz
      cd hdf5-1.10.6
      ```
  
  2. Run the configure script to set up the compilation. 
  There are two important configuration flags to set:
  The installation prefix (`--prefix ${HOME}/custom-hdf5`)
  and that enabling Fortran (`--enable-fortran`).
  
      ```sh
      ./configure --prefix=${HOME}/custom-hdf5 --enable-fortran
      ```
      
  Make sure this command completes without errors -- at the end, you should see a list of options that have and have not been enabled.
     
   3. Compile HDF5.
   This will probably take a while and will produce a lot of output.
   
       ```sh
       make install
       ```
       
   Again, check that this did not exit with errors (there will be a lot of warnings, which can be ignored).
   
   
       ```sh
       ~/custom-hdf5/bin/h5dump --version
       ```
   1. Check that HDF5 compiled by running one of the compiled executables.
       
4. Clone the ED2 source code and switch to the ED-2.2 branch (`mpaiao_pr`).
(I'm returning to your home directory and assuming commands are happening from there, but you can do this in any directory you want.)

    ```sh
    cd ~
    git clone https://github.com/edmodel/ed2
    cd ed2
    git checkout -b mpaiao_pr origin/mpaiao_pr
    ```
    
5. We need to create a new `include.mk.pic` file with special compilation settings for PIC.
First, copy the existing `include.mk.gfortran` file.

    ```sh
    cp ED/build/make/include.mk.gfortran ED/build/make/include.mk.pic
    ```
    
    Now, open the file in a text editor (I assume `vim`)...
    
    ```sh
    vim ED/build/make/include.mk.pic
    ```
    
    ...and make the following changes:
    
    (1) Set the `HDF5_HOME` value to `/your/home/directory/custom-hdf5`, replacing `/your/home/directory` with the absolute path of your home directory (you can find it out by `cd ~` followed by `pwd`).
    
    (2) Add the following to the beginning of `HDF5_LIBS`: `-L${HDF5_HOME}/lib`.
    It should now look like `HDF5_LIBS=-L${HDF5_HOME}/lib -lhdf5 -lhdf5_fortran -lhdf5_hl -lz`.
    
    (2) Set `USE_MPIWTIME` to 0.
    
    (3) Set `F_COMP=gfortran`, `C_COMP=gcc`, and `LOADER=gfortran`.
    
    (4) Remove all occurrences of `-fopenmp` from `F_OPTS` and `C_OPTS` in both of the `KIND_COMP` sections.
    
    (5) Comment out the `MPI_PATH`, `PAR_INCS`, `PAR_LIBS`, and `PAR_DEFS` variables.
    
    Explanation: (1) and (2) make sure you are using the version of HDF5 that you compiled with the correct version of GCC.
    (3), (4), and (5) disable MPI execution, which requires a lot of special flags and extra modules to work, and does nothing (or may even be counterproductive) for single-site runs.
    
    Save the file and exit.
    
6. Now, we can compile ED2.
Change into the build directory...

    ```sh
    cd ED/build
    ```
    
    ...and run the `install.sh` script, specifying the correct platform and compilation kind.
    
    ```sh
    ./install.sh -k E -p pic -g
    ```
    
    If you immediately see a bunch of warnings about "non-existent include directory", stop the compilation and check the paths in the `include.mk.pic` file.
    
7. The compilation should create a file like `ed_2.2-opt` in the current directory.
This is the ED2 executable, and should technically be self-contained.
However, because of how HDF5 libraries were installed, as well as the module dependencies, ED2 may not be able to run without a bit of additional configuration.
It's therefore a good idea to create a small wrapper script that will do the configuration steps and then call ED2.
Such a script (let's call it `ED/build/ed2`) might look something like this:

    ```sh
    #!/bin/sh

    # Unload any currently loaded modules
    # (only inside the script -- does not affect your interactive environment)  
    module purge
    
    # Load correct GCC module
    module load gcc/5.2.0
    
    # Remove the stack limit -- may not be necessary, but sometimes prevents
    # segmentation faults.
    ulimit -s unlimited
    
    # Add the custom HDF5 library path to the library search path
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/your/home/directory/custom-hdf5
    
    # Run ED2, passing all command line arguments to it
    # (`$@` means "all arguments to the current script").
    # Note the absolute path to ED2 to make sure there is no ambiguity related to
    # the current working directory.
    /path/to/home/directory/ed2/ED/build/ed_2.2-opt $@
    ```
    
7. Once this finishes, try a test UMBS run. 
If it succeeds, you are good to go!

## Test run

ED2 ships with a basic set of tests that can be used to check that its functionality works.
These are stored in the `EDTS` directory in the repository root.
Doing a test run at UMBS from bare ground is as simple as:

```sh
cd EDTS
./run-test.sh umbs.bg ../ED/build/ed_2.2-opt
```

This script will download the required input files and perform a test simulation.
For more info on how this works, see the `EDTS/README.md` file.

This test produces monthly output files that will be stored in `EDTS/test-outputs/umbs.bg/`.
Here is an example R script that reads NPP, GPP, and autotrophic and heterotrophic respiration from these files and generates a simple plot.

``` r
library(ncdf4)

# Replace with your to ED2 root directory
ed2_dir <- "~/Projects/edmodel/ed2-umbs-test/"

outdir <- file.path(
  ed2_dir,
  "EDTS/test-outputs/umbs.bg"
)
ncfiles <- list.files(outdir, full.names = TRUE)

# Look at one file
nc1 <- nc_open(ncfiles[1])

# List all available variable names
names(nc1$var)
#>   [1] "AGB_CO"                      "AGB_PY"
#>   [3] "AGE"                         "AREA"
#>   [5] "AREA_SI"                     "AVG_MONTHLY_WATERDEF"
# <...>
#>  [75] "MMEAN_ALBEDO_NIR_PY"         "MMEAN_ALBEDO_PAR_PY"
#>  [77] "MMEAN_ALBEDO_PY"             "MMEAN_ATM_CO2_PY"
#>  [79] "MMEAN_ATM_PAR_DIFF_PY"       "MMEAN_ATM_PAR_PY"
#>  [81] "MMEAN_ATM_PRSS_PY"           "MMEAN_ATM_RHOS_PY"
# <...>
#> [325] "SLXSAND"                     "SLZ"
#> [327] "VEG_HEIGHT"                  "VEG_ROUGH"
#> [329] "VM_BAR"                      "WAI_CO"
#> [331] "WAI_PY"                      "WORKLOAD"
#> [333] "XATM"                        "YATM"

# Read multiple variables from a single file as colums of a data.frame
read_vars <- function(file, vars) {
  nc <- ncdf4::nc_open(file)
  # Probably not strictly necessary, but good practice
  on.exit(ncdf4::nc_close(nc), add = TRUE)
  result_list <- lapply(vars, ncdf4::ncvar_get, nc = nc)
  names(result_list) <- vars
  do.call(data.frame, result_list)
}

# Net (NPP) and Gross (GPP) primary productivity,
# heterotrophic respiration (RH), and autotrophic (plant) respiration (PLRESP).
# `MMEAN` means "monthly mean".
# `PY` means for the entire patch.
vars <- sprintf("MMEAN_%s_PY", c("NPP", "GPP", "RH", "PLRESP"))
results <- lapply(ncfiles, read_vars, vars = vars)
result_df <- do.call(rbind, results)

par(mfrow = c(2, 2))
for (v in vars) {
  plot(result_df[[v]], type = "l",
       xlab = "Month", ylab = v)
}
```

![](https://i.imgur.com/nT7uGcO.png)
