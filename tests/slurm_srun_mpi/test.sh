#!/bin/bash
#@ description: srun launches an MPI program directly (PMIx), 4 ranks across 2 nodes, no mpirun
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param srun_mpi = pmix
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 2
#@ time: 10
#@ local: no
#@ tags: scheduler mpi

# srun_mpi: the PMI plugin the MPI was built for (srun --mpi=list shows what Slurm offers).
out=$(srun --mpi="$srun_mpi" ./mpi_hello)
echo "$out" | awk '{print $1, $2, $3, $4, $7, $8}' | sort -k2,2n
echo "distinct nodes: $(echo "$out" | awk '{print $6}' | sort -u | wc -l)"
