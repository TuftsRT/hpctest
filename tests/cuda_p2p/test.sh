#!/bin/bash
#@ description: 2 GPUs of one node: peer-to-peer copies both ways and direct peer reads, data checked
#@ param cuda = nvhpc
#@ modules: ${cuda}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ gpus: 2
#@ time: 10
#@ baseline-by: gpu
#@ tags: gpu

# P2P over a PCIe switch with ACS on (or IOMMU not in passthrough) can hang or corrupt data;
# the timeout turns a hang into a FAIL that shows the GPU topology.
timeout 120 ./cuda_p2p
rc=$?
if [ $rc -eq 124 ]; then
    echo "hung: killed after 120 s"
    nvidia-smi topo -m | grep '^GPU'
fi
exit $rc
