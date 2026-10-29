#!/bin/bash
#@ description: hwloc sees the node topology and exactly the job's CPUs
#@ param hwloc = hwloc
#@ modules: ${hwloc}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 5
#@ tags: tool node

lstopo-no-graphics --of console > topo.txt
grep -qE '^Machine' topo.txt && echo "lstopo: machine found"
[ "$(hwloc-calc --number-of package all)" -ge 1 ] && echo "packages >= 1"
[ "$(hwloc-calc --number-of numanode all)" -ge 1 ] && echo "NUMA nodes >= 1"
# hwloc restricts itself to the cgroup's allowed CPUs, like nproc.
pu=$(hwloc-calc --number-of pu all)
echo "allowed PUs = nproc: $([ "$pu" = "$(nproc)" ] && echo yes || echo "no ($pu vs $(nproc))")"
echo "allowed PUs = SLURM_CPUS_PER_TASK: $([ "$pu" = "${SLURM_CPUS_PER_TASK:-$pu}" ] && echo yes || echo "no ($pu)")"
