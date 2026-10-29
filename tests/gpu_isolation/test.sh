#!/bin/bash
#@ description: a 1-GPU job sees exactly one GPU (Slurm cgroup device constraint)
#@ ntasks: 1
#@ gpus: 1
#@ time: 5
#@ local: no
#@ tags: gpu scheduler

# Without ConstrainDevices=yes in cgroup.conf, a job can open every GPU on the node
# even though CUDA_VISIBLE_DEVICES lists only its own; nvidia-smi then shows them all.
IFS=, read -ra visible <<< "${CUDA_VISIBLE_DEVICES:-}"
echo "CUDA_VISIBLE_DEVICES entries: ${#visible[@]}"
echo "GPUs nvidia-smi can open: $(nvidia-smi -L 2>/dev/null | grep -c '^GPU ')"
echo "/dev/nvidia[0-9]* usable: $(for d in /dev/nvidia[0-9]*; do
    (exec 3<"$d") 2>/dev/null && echo "$d"; done | wc -l)"
