#!/bin/bash
#@ description: TensorFlow sees the GPU and multiplies matrices on it
#@ param tensorflow = tensorflow
#@ modules: ${tensorflow}
#@ ntasks: 1
#@ cpus-per-task: 6
#@ gpus: 1
#@ time: 15
#@ tags: app ml gpu

python3 mmult.py > tf.log 2>&1
rc=$?
grep -E '^GPUs are available|^Matrix multiplication result shape' tf.log
[ $rc -eq 0 ] || { grep -v '^\s*$' tf.log | tail -5 >&2; exit $rc; }
