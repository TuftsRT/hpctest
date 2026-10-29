#!/bin/bash
#@ description: a job step that runs past its 1-minute time limit is killed and recorded as TIMEOUT
#@ ntasks: 1
#@ time: 10
#@ local: no
#@ stderr: ignore
#@ tags: scheduler

start=$(date +%s)
srun -n1 --time=1 sleep 600
echo "step killed before finishing: $( (( $(date +%s) - start < 400 )) && echo yes || echo no)"

# slurmdbd records the step a few seconds after it ends.
for i in $(seq 30); do
    state=$(sacct -n -P -j "$SLURM_JOB_ID.0" -o State | head -1)
    [[ -n $state && $state != RUNNING ]] && break
    sleep 5
done
echo "sacct state: ${state%% *}"
