#!/bin/bash
#@ description: ScaLAPACK pdgesv on a 2x2 BLACS grid (4 MPI ranks, 2 nodes)
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param scalapack = netlib-scalapack
#@ param scalapack_libs = -lscalapack -lopenblas
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi} ${scalapack}
#@ nodes: 2
#@ ntasks: 4
#@ time: 10
#@ tags: lib mpi

$mpirun -n 4 ./scalapack_test
