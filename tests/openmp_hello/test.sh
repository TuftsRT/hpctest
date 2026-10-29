#!/bin/bash
#@ description: OpenMP program runs a parallel region with 2 threads
#@ param compiler = gcc
#@ param cc = gcc
#@ param ompflag = -fopenmp
#@ modules: ${compiler}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 5
#@ tags: compiler openmp quick

export OMP_NUM_THREADS=2
./hello
