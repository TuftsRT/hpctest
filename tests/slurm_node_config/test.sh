#!/bin/bash
#@ description: node hardware matches Slurm's node definition (CPUs, threads/core, memory)
#@ ntasks: 1
#@ exclusive: yes
#@ time: 5
#@ local: no
#@ tags: scheduler

node=$(hostname -s)
conf=$(scontrol show node "$node")
get() { echo "$conf" | grep -o "$1=[^ ]*" | head -1 | cut -d= -f2; }
s_cpus=$(get CPUTot); s_tpc=$(get ThreadsPerCore); s_mem=$(get RealMemory)
o_cpus=$(grep -c '^processor' /proc/cpuinfo)
o_tpc=$(lscpu | awk -F: '/^Thread\(s\) per core/ {gsub(/ /, "", $2); print $2}')
o_mem=$(awk '/^MemTotal/ {print int($2 / 1024)}' /proc/meminfo)

check() {   # label, ok-condition, details
    if eval "$2"; then echo "$1: ok"; else echo "$1: MISMATCH ($3)"; fi
}
check "CPUs"             "[ $o_cpus -eq $s_cpus ]"   "OS $o_cpus, Slurm CPUTot $s_cpus"
check "threads per core" "[ $o_tpc -eq $s_tpc ]"     "OS $o_tpc, Slurm $s_tpc"
check "memory"           "[ $s_mem -le $o_mem ]"     "Slurm RealMemory $s_mem MB > OS $o_mem MB"
