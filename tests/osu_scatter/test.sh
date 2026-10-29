#!/bin/bash
#@ description: OSU scatter latency (us) (8 nodes, 1 rank each)
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 8
#@ tasks-per-node: 1
#@ exclusive: yes
#@ time: 10
#@ tags: benchmark mpi network

$mpirun -n 8 ./osu_scatter -m 524288 | grep -v '^#' | awk 'NF {print $1, $2}'
