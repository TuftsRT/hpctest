#!/bin/bash
#@ description: OSU point-to-point latency (us) (2 nodes, 1 rank each)
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 1
#@ exclusive: yes
#@ time: 10
#@ tags: benchmark mpi network

$mpirun -n 2 ./osu_latency  | grep -v '^#' | awk 'NF {print $1, $2}'
