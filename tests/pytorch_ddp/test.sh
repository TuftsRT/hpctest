#!/bin/bash
#@ description: PyTorch DDP on 2 GPUs of one node (torchrun, NCCL): exact all-reduce, synced weights, bus GB/s
#@ param pytorch = pytorch
#@ modules: ${pytorch}
#@ ntasks: 1
#@ cpus-per-task: 4
#@ gpus: 2
#@ time: 15
#@ baseline-by: gpu
#@ tags: app ml gpu

# NCCL_DEBUG=INFO logs the transport NCCL picks (P2P/NVLink, P2P/IPC, SHM, ...).
export NCCL_DEBUG=INFO NCCL_DEBUG_FILE=$PWD/nccl.%h.%p.log OMP_NUM_THREADS=1
timeout 600 python -m torch.distributed.run --standalone --nproc-per-node=2 ddp.py 2> ddp.err
rc=$?
echo "nccl transport: $(cat nccl.*.log 2>/dev/null | grep -oE 'via (P2P|SHM|NET)/[A-Za-z0-9_/]+' | sort -u | sed 's/^via //' | xargs)"
[ $rc -eq 124 ] && echo "hung: killed after 600 s (NCCL P2P problem? try NCCL_P2P_DISABLE=1)"
[ $rc -ne 0 ] && grep -v NCCL ddp.err | tail -20 >&2
exit $rc
