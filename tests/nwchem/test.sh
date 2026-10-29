#!/bin/bash
#@ description: NWChem H2O SCF + MP2 (6-31G*), 4 MPI ranks on 2 nodes; energies vs reference
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param nwchem = nwchem
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi} ${nwchem}
#@ nodes: 2
#@ tasks-per-node: 2
#@ mem: 4G
#@ time: 10
#@ local: no
#@ tags: app chem mpi

$mpirun -n 4 nwchem h2o.nw > nwchem.out 2> nwchem.err || { tail -20 nwchem.out nwchem.err >&2; exit 1; }
grep -m1 -E '^ *nproc *=' nwchem.out | tr -s ' '
awk '/Total SCF energy =/ && !s { printf "SCF energy %.6f\n", $5; s = 1 }
     /Total MP2 energy/ { printf "MP2 energy %.6f\n", $4 }' nwchem.out
