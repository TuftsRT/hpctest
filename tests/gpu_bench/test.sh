#!/bin/bash
#@ description: GPU memory bandwidth, host<->device bandwidth, FP32 and FP16 tensor-core GEMM
#@ param cuda = nvhpc
#@ modules: ${cuda}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ gpus: 1
#@ time: 10
#@ baseline-by: gpu
#@ tags: benchmark gpu

./gpu_bench
