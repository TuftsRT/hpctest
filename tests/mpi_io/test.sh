#!/bin/bash
#@ description: MPI-IO collective write/read of one shared file from 2 nodes (128 MB), verified
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 4
#@ time: 10
#@ tags: mpi io

# Runs in the job directory, which is on the shared file system hpctest runs from.
echo "file system: $(stat -f -c %T .)"
timeout 300 $mpirun -n 8 ./mpi_io
