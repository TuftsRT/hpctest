#!/bin/bash
#@ description: PnetCDF: 4 MPI ranks write a shared file; compare with a reference
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param pnetcdf = parallel-netcdf
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi} ${pnetcdf}
#@ nodes: 2
#@ ntasks: 4
#@ time: 10
#@ tags: lib mpi

$mpirun -n 4 ./pnetcdf-write-standard
$mpirun -n 1 ncmpidiff -q testfile.nc test.nc && echo "files match"
