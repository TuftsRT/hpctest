#!/bin/bash
#@ description: PyTorch trains a small network on the CPU
#@ param pytorch = pytorch
#@ modules: ${pytorch}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ time: 15
#@ tags: app ml

python test.py
