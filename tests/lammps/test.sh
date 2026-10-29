#!/bin/bash
#@ description: LAMMPS Lennard-Jones melt (4000 atoms, 4 MPI ranks): thermo and energy conservation
#@ param lammps = lammps
#@ param lmp = lmp
#@ param mpirun = mpirun
#@ modules: ${lammps}
#@ ntasks: 4
#@ time: 10
#@ tags: app chem mpi

$mpirun -n 4 $lmp -in in.lj -log none > lmp.out || { cat lmp.out >&2; exit 1; }
# Thermo table: the row after the "Step" header is step 0, the last row before
# "Loop time" is the final step. Column order is set by thermo_style in in.lj.
awk '$1 == "Step" { t = 1; next }
     /^Loop time/ { t = 0; print; next }
     t && $1 ~ /^[0-9]+$/ { if (n++ == 0) e0 = $5; s = $1; e = $5;
                            if ($1 == 0) printf "step 0: temp %.4f epair %.4f etotal %.4f press %.4f\n", $2, $3, $5, $6 }
     END { d = (e - e0) / e0; if (d < 0) d = -d
           printf "final step %d, relative energy drift %s\n", s, d < 0.01 ? "< 1%" : d }' lmp.out
