#!/bin/bash
#@ description: cgroup memory limit equals the job's --mem request (2000 MB)
#@ ntasks: 1
#@ mem: 2000M
#@ time: 5
#@ local: no
#@ tags: scheduler quick

# This job's cgroup: v2 = our own cgroup minus the "/step_*" part; v1 = Slurm's layout.
cg=$(awk -F: '$1=="0"{print $3}' /proc/self/cgroup)
if [[ -n $cg ]]; then
    echo "cgroup v2"
    jobcg=/sys/fs/cgroup${cg%/step_*}
else
    echo "cgroup v1"
    jobcg=/sys/fs/cgroup/memory/slurm/uid_$(id -u)/job_$SLURM_JOB_ID
fi
f=$jobcg/memory.max
[[ -f $f ]] || f=$jobcg/memory.limit_in_bytes
echo "cgroup memory limit: $(( $(cat $f) / 1024 / 1024 )) MB"
