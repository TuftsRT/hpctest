#!/bin/bash
#@ description: CUDA compiler (nvcc) builds and runs a vector add on a GPU
#@ param cuda = nvhpc
#@ modules: ${cuda}
#@ ntasks: 1
#@ gpus: 1
#@ time: 10
#@ tags: gpu compiler

./vector_add
