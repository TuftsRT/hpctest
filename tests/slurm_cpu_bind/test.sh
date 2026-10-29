#!/bin/bash
#@ description: srun -n 2 -c 4 gives each task its own 4 CPUs (task affinity), not the job's whole CPU set
#@ ntasks: 2
#@ cpus-per-task: 4
#@ time: 5
#@ local: no
#@ tags: scheduler

# Without task/affinity in TaskPlugin (or with cpu binding disabled), every task of a step
# can run on all the job's CPUs: hybrid MPI+OpenMP and multi-task jobs then pile threads
# onto the same cores. Each task prints the CPUs it may run on.
srun -n 2 -c 4 --cpu-bind=cores bash -c 'echo "$SLURM_PROCID $(taskset -cp $$ | sed "s/.*: //")"' \
    > tasks.txt || exit 1
sort -n tasks.txt >&2
expand() { tr ',' '\n' <<< "$1" | awk -F- '{ if (NF == 2) for (i = $1; i <= $2; i++) print i; else print $1 }'; }
t0=$(expand "$(awk '$1 == 0 {print $2}' tasks.txt)" | sort -n)
t1=$(expand "$(awk '$1 == 1 {print $2}' tasks.txt)" | sort -n)
echo "task 0 CPUs: $(echo "$t0" | wc -l)"
echo "task 1 CPUs: $(echo "$t1" | wc -l)"
echo "CPUs shared by both tasks: $(comm -12 <(echo "$t0") <(echo "$t1") | wc -l)"
