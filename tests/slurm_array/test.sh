#!/bin/bash
#@ description: a 3-task job array runs every task with its own SLURM_ARRAY_TASK_ID
#@ ntasks: 1
#@ time: 20
#@ local: no
#@ tags: scheduler

# Sub-jobs go to this job's partition/account/QOS; they are cancelled if this job ends.
opts=(--parsable -J hpctest-sub -n1 -t 2 --mem=200M -o /dev/null
      ${SLURM_JOB_PARTITION:+-p "$SLURM_JOB_PARTITION"} ${SLURM_JOB_ACCOUNT:+-A "$SLURM_JOB_ACCOUNT"}
      ${SLURM_JOB_QOS:+-q "$SLURM_JOB_QOS"})
id=$(sbatch "${opts[@]}" --array=1-3 --wrap 'echo task $SLURM_ARRAY_TASK_ID > task.$SLURM_ARRAY_TASK_ID')
[[ $id =~ ^[0-9]+$ ]] || { echo "sbatch failed: $id"; exit 0; }
trap 'scancel "$id" 2>/dev/null' EXIT

while [[ -n $(squeue -h -j "$id" -o %i 2>/dev/null) ]]; do sleep 10; done
echo "task outputs: $(cat task.* 2>/dev/null | awk '{print $2}' | sort -n | xargs)"
for i in $(seq 12); do      # slurmdbd may lag a little behind squeue
    states=$(sacct -n -X -P -j "$id" -o State | sort | uniq -c | xargs)
    [[ $states == "3 COMPLETED" ]] && break
    sleep 5
done
echo "sacct: $states"
