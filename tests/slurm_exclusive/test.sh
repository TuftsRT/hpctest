#!/bin/bash
#@ description: --exclusive jobs are not shared with other jobs
#@ ntasks: 1
#@ exclusive: yes
#@ time: 5
#@ local: no
#@ tags: scheduler

squeue -h -j $SLURM_JOB_ID -o '%h'
