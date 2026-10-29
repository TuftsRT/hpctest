#!/bin/bash
#@ description: MPI data correctness across 4 nodes: sendrecv to 32 MB, isend, bcast, allreduce, alltoall
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 4
#@ tasks-per-node: 4
#@ mem: 8G
#@ time: 10
#@ tags: mpi

# Messages are verified element by element: a transport that drops or corrupts data
# (or hangs on large messages) fails here, where mpi_hello's single integer would pass.
timeout 300 $mpirun -n 16 ./mpi_collectives
