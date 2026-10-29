#!/bin/bash
#@ description: PyTorch DDP across 2 nodes x 1 GPU (srun + torchrun, NCCL over the network): sum, sync, GB/s
#@ param pytorch = pytorch
#@ param port = 29517
#@ modules: ${pytorch}
#@ nodes: 2
#@ tasks-per-node: 1
#@ cpus-per-task: 4
#@ gpus: 1
#@ time: 15
#@ local: no
#@ baseline-by: gpu
#@ tags: app ml gpu network

# One torchrun per node; rendezvous on the first node of the allocation.
# NCCL_DEBUG=INFO shows whether NCCL found InfiniBand/RoCE (NET/IB) or fell back to TCP (NET/Socket).
master=$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -1)
export NCCL_DEBUG=INFO NCCL_DEBUG_FILE=$PWD/nccl.%h.%p.log OMP_NUM_THREADS=1
timeout 600 srun --ntasks-per-node=1 bash -c "python -m torch.distributed.run --nnodes=2 \
    --nproc-per-node=1 --node-rank=\$SLURM_NODEID --master-addr=$master --master-port=$port \
    ddp.py" 2> ddp.err
rc=$?
echo "nccl transport: $(cat nccl.*.log 2>/dev/null | grep -oE 'via (P2P|SHM|NET)/[A-Za-z0-9_/]+' | sort -u | sed 's/^via //' | xargs)"
[ $rc -eq 124 ] && echo "hung: killed after 600 s"
[ $rc -ne 0 ] && grep -v NCCL ddp.err | tail -20 >&2
exit $rc
