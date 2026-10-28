#!/bin/bash
#@ description: TensorFlow matrix multiply on the CPU
#@ param tensorflow = tensorflow
#@ modules: ${tensorflow}
#@ ntasks: 2
#@ time: 15
#@ stderr: ignore
#@ tags: app ml

python3 mmult.py 2>/dev/null
