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

``` sh
git checkout mpaiao_pr
```

Refer to the ED2 repository README file for the general structure of the ED2 code.

## Compiling the model

Switch into the build directory.

``` sh
cd ED/build
```

ED2 is installed via the `install.sh` script found in this directory.
It has the following general syntax:

``` sh
./install.sh -k <kind> -p <platform> [-g] [--clean]
# E.g.
# ./install.sh -k A -p macos_homebrew -g
```

The options above are as follows:

- `<kind>` -- Either `A` for a "debug" build that compiles and runs more slowly, but has more information for debugging (the resulting executable will end in `dbg`); or `E` for an "optimized" build with a faster runtime (the resulting executable will end in `opt`). Unless you are developing ED2, you probably want `E`.
- `<platform>` -- The system on which you are compiling. This exactly corresponds to the files `ED/build/make/include.mk.<platform>`. For instance, for MacOS with libraries installed via Homebrew, use `-p macos_homebrew`, which will read variables from `ED/build/make/include.mk.macos_homebrew`. You can also create your own `include.mk.*` files, or modify existing ones, as necessary.
- `-g` -- An optional flag that disables tagging with the current Git hash. By default, the resulting binary looks something like `ed_2.2-opt-<githash>`, but with `-g`, the binary is just `ed_2.2-opt`, which is usually easier to work with.
- `--clean` -- If included, this will delete all compiled files and the binary corresponding to the installation "kind" and platform. Note that all of the other flags are required for this to work. I.e. To recompile ED2 from scratch, you'll need to run something like:
  ```sh
  # Clear the current installation
  ./install.sh -k A -p macos_homebrew -g --clean
  # Install
  ./install.sh -k A -p macos_homebrew -g
  ```
  
This install script will create a directory of compiled `.o` objects, a statically-compiled library (`ed_2.2-opt.a`), and the executable itself `ed_2.2-opt`.

### Special instructions for MacOS

These instructions assume you are using [Homebrew](https://brew.sh) to manage your system libraries.
Using Homebrew, install (`brew install`) the following libraries:

- `gfortran`: The GCC Fortran compiler
- `hdf5`: Libraries for HDF5 files

### Special instructions for PIC
