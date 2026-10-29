#!/bin/bash
#@ description: PyTorch trains a small network on a GPU
#@ param pytorch = pytorch
#@ modules: ${pytorch}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ gpus: 1
#@ time: 15
#@ tags: app ml gpu

python test.py
