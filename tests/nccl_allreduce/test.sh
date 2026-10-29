#!/bin/bash
#@ description: NCCL all-reduce across 2 GPUs of one node: correct sum and bus bandwidth
#@ param cuda = nvhpc
#@ modules: ${cuda}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ gpus: 2
#@ time: 10
#@ baseline-by: gpu
#@ tags: benchmark gpu

./nccl_allreduce
