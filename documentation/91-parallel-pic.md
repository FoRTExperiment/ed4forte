# Tips for Running ED2 on PIC

## Quick start: Simple batch script

A simple `sbatch` script for ED2 might look something like this.

``` sh
#!/bin/bash
#SBATCH -A forteproject
#SBATCH --time 02-00:00
#SBATCH --nodes 1
#SBATCH --job-name=forte_ed2
#SBATCH --output=/qfs/projects/forteproject/logs/%A_%a.log

# Unload all modules
module purge
# Load required modules
module load gcc/5.2.0

# Eliminate the stack limit. Otherwise, ED2 trigger a segmentation fault
# because # it overloads the stack. May not be necessary depending on exact
# compile flags, but doesn't hurt.
ulimit -s unlimited

# Run ED2
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.file
```

This script will run for a maximum of 2 days, on 1 node, and will send both output (`stdout`) and error (`stderr`) streams to the same file (tagged with the Job ID -- `%A` -- and the array index -- `%a`).

**NOTE**: Any relative paths in the `ED2IN`, `ED_MET_DRIVER_HEADER`, and any other files that specify paths, are relative to **current working directory**; i.e. the directory from which ED2 is executed (or from which the `sbatch` command is executed).
It may be a good idea to tweak any input files used for PIC simulations to use absolute paths to avoid ambiguity.
On the other hand, relative paths are more portable in case you want to copy directories to different places.
