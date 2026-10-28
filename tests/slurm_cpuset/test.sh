#!/bin/bash
#@ description: cgroups confine a 4-task job to exactly 4 CPUs
#@ ntasks: 4
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
    jobcg=/sys/fs/cgroup/cpuset/slurm/uid_$(id -u)/job_$SLURM_JOB_ID
fi
f=$jobcg/cpuset.cpus.effective
[[ -f $f ]] || f=$jobcg/cpuset.cpus
echo "cpus in job cgroup: $(python3 - "$f" <<'EOF'
import sys
n = 0
for part in open(sys.argv[1]).read().strip().split(","):
    a, _, b = part.partition("-")
    n += int(b or a) - int(a) + 1
print(n)
EOF
)"
