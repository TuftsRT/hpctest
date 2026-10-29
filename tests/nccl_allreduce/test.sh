#!/bin/bash
#@ description: NCCL all-reduce across 2 GPUs of one node: correct sum and bus bandwidth
#@ param cuda = nvhpc
#@ modules: ${cuda}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ gpus: 2
#@ time: 10
#@ baseline-by: gpu
#@ tags: benchmark gpu

# A hang (typically GPU peer-to-peer over PCIe blocked by ACS/IOMMU) becomes a FAIL with
# the output so far, instead of the job hitting its time limit with nothing to show.
timeout 300 ./nccl_allreduce
rc=$?
if [ $rc -eq 124 ]; then
    echo "hung: killed after 300 s (try NCCL_P2P_DISABLE=1 to confirm a P2P problem)"
    echo "GPUs: $(nvidia-smi --query-gpu=pci.bus_id --format=csv,noheader | xargs)"
    nvidia-smi topo -m | grep '^GPU'
fi
exit $rc
