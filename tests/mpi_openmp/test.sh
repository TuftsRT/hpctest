#!/bin/bash
#@ description: hybrid MPI+OpenMP, 2 nodes x 2 ranks x 4 threads: every thread on its own CPU
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param mpicc = mpicc
#@ param mpirun = mpirun
#@ param ompflag = -fopenmp
#@ param mpirun_opts = --map-by ppr:2:node:pe=4 --bind-to core
#@ modules: ${compiler} ${mpi}
#@ nodes: 2
#@ tasks-per-node: 2
#@ cpus-per-task: 4
#@ time: 10
#@ tags: mpi openmp

# mpirun_opts: how this MPI gives each rank cpus-per-task cores (Open MPI syntax by default;
# Intel MPI: "-ppn 2" with I_MPI_PIN_DOMAIN=omp, MVAPICH2: "-ppn 2" with MV2_CPU_BINDING_LEVEL).
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-4} OMP_PLACES=cores OMP_PROC_BIND=close
timeout 120 $mpirun -n 4 $mpirun_opts ./mpi_openmp
