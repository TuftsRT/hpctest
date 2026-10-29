#!/bin/bash
#@ description: MPI hello + allreduce, 4 ranks across 2 nodes
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 2
#@ time: 10
#@ tags: mpi quick

out=$($mpirun -n 4 ./mpi_hello)
echo "$out" | awk '{print $1, $2, $3, $4, $7, $8}' | sort -k2,2n
echo "distinct nodes: $(echo "$out" | awk '{print $6}' | sort -u | wc -l)"
