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

## Running multiple ED2 simulations in parallel

If you compiled ED2 without MPI support (i.e. followed the exact compilation instructions in this repository), an ED2 simulation will use only a single core.
A typical PIC node has 24 cores, so you can run up to 24 instances of ED2 in parallel on a single node.
The way to do this is to use a script similar to the one above, but to run each ED2 simulation in the background:

``` sh
#!/bin/bash
#SBATCH -A forteproject
#...etc...

# Assuming you have 5 runs you want to do, each with a dedicated ED2IN.runX file
# The `> file` redirects stdout to `file`.
# The `2>&1` redirects stderr (2) to the same place as stdout (&1), which is to `file`.
# The trailing `&` means run that particular process in the background.
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run1 > /qfs/projects/forteproject/logs/run1.log 2>&1 &
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run2 > /qfs/projects/forteproject/logs/run2.log 2>&1 &
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run3 > /qfs/projects/forteproject/logs/run3.log 2>&1 &
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run4 > /qfs/projects/forteproject/logs/run4.log 2>&1 &
/path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run5 > /qfs/projects/forteproject/logs/run5.log 2>&1 &

# This tells the script to wait until all background processes have finished.
wait

# Finally, print this before exiting!
echo "All simulations finished!"
```

For large numbers of simulations, you can abbreviate this with a bash `for-do` loop:

``` sh
for I in $(seq 1 24); do
    echo "Submitting run $I"
    /path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run$I > /qfs/projects/forteproject/logs/run$I.log 2>&1 &
done

wait

echo "All simulations finished!"
```

For running more than 24 simulations, I would recommend combining this with array jobs.
If you want to do 100 simulations, at 24 per run, you need to request 5 array jobs.
For array index $I$, each job needs to do runs $1 + 24 \times (I - 1)$ to $24 \times I$.
This can be done with a bash script like the following.

``` sh
#!/bin/bash
#SBATCH ... # standard SBATCH instructions
#SBATCH --array=1-5

# `$((...))` is bash syntax for integer calculations.
# The `...` expression is evaluated as simple math.
IM1=$(($SLURM_ARRAY_TASK_ID - 1))
A=$((1 + 24 * $IM1))
B=$((24 * $SLURM_ARRAY_TASK_ID))

# This uses the bash "condition operator" `?` to perform a simple conditional:
# If $B is greater than 100, then set it to 100; otherwise, just use the value
# of $B. This prevents us from trying to submit runs for which ED2IN files
# don't exist.
B=$(($B > 100 ? 100 : $B))

echo "Running simulations $A to $B"
for I in $(seq $A $B); do
    echo "Submitting run $I"
    /path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run$I > /qfs/projects/forteproject/logs/run$I.log 2>&1 &
done
wait
echo "Done!"
```

**NOTE**: In this example, make sure that you set up each `ED2IN.runX` file to write to a _different_ directory (or at least use a different file prefix).
ED2 will silently overwrite existing files as new simulations are happening!

## Process ED2 outputs as part of the run

Reading outputs from long ED2 simulations can take a long time.
Therefore, it's a good idea to leverage PIC to read the outputs as they're being produced.
We can do this by creating a bash function for both running ED2 and then reading its output.

Suppose that each `ED2IN.runX` file writes its output to directory `/path/to/output/runX`.
Suppose also that you have an R script (`/path/to/process-output.R`) that takes an output directory as a command line argument and aggregates the output from a single output into a single, convenient file.
For each simulation, you would want to first run ED2 and then process the output.

You can automate this process with bash as follows:

``` sh
#!/bin/bash
#...all of your SBATCH directives...
#SBATCH --array=1-5

# Define the function
runAndProcess() {
    # Bash cannot do named function arguments, only positional ones
    $RUNNUMBER=$1
    echo "Submitting run $RUNNUMBER"
    /path/to/ed2/ED/build/ed_2.2-opt -f /path/to/my/ED2IN.run$RUNNUMBER 

    # Once the simulation is complete, process the output
    echo "Reading outputs"
    Rscript /path/to/process-output.R /path/to/output/run$RUNNUMBER
    echo "Done with run $RUNNUMBER"
}

# Now, do what you did before, but call the function at each step.
IM1=$(($SLURM_ARRAY_TASK_ID - 1))
A=$((1 + 24 * $IM1))
B=$((24 * $SLURM_ARRAY_TASK_ID))
B=$(($B > 100 ? 100 : $B))

echo "Running simulations $A to $B"
for I in $(seq $A $B); do
    runAndProcess $I > /qfs/projects/forteproject/logs/run$I.log 2>&1 &
done
wait
echo "Done!"
```
