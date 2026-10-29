#!/bin/bash
#@ description: CUDA-aware MPI between GPUs on 2 nodes: device-buffer sendrecv/allreduce/bcast, GB/s
#@ param mpi = openmpi
#@ param cuda =
#@ param mpicxx = mpicxx
#@ param mpirun = mpirun
#@ modules: ${mpi} ${cuda}
#@ nodes: 2
#@ tasks-per-node: 1
#@ cpus-per-task: 2
#@ gpus: 1
#@ time: 10
#@ baseline-by: gpu
#@ tags: gpu mpi

# mpi: an MPI built with CUDA support (for Open MPI: UCX with the cuda transports).
timeout 300 $mpirun -n 2 ./cuda_mpi
