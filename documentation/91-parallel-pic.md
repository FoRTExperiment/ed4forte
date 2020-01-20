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
#SBATCH --output=/qfs/projects/forteproject/logs/%A_%a.log

# Unload all modules
module purge
# Load required modules
module load gcc/5.2.0

# Eliminate the stack limit. Otherwise, ED2 may do a segmentation fault because
# it overloads the stack. May not be necessary depending on exact compile
# flags, but doesn't hurt.
ulimit -s unlimited

# Run ED2
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.file
```
