"""PyTorch DistributedDataParallel over NCCL, launched by torchrun (one or more nodes).

Checks: every rank gets its own GPU, an all-reduce gives the exact sum, a short DDP
training run lowers the loss, and the model weights are bit-identical on all ranks
afterwards (gradients really were averaged). Rank 0 prints the results and the
all-reduce bus bandwidth.
"""
import os
import socket
import time

import torch
import torch.distributed as dist
import torch.nn as nn
from torch.nn.parallel import DistributedDataParallel as DDP

dist.init_process_group("nccl")
rank, world = dist.get_rank(), dist.get_world_size()
local_rank = int(os.environ["LOCAL_RANK"])
torch.cuda.set_device(local_rank)
dev = torch.device("cuda", local_rank)

# Placement: host and GPU UUID of every rank.
info = (socket.gethostname(), str(getattr(torch.cuda.get_device_properties(dev), "uuid", local_rank)))
placement = [None] * world
dist.all_gather_object(placement, info)

# Exact all-reduce: rank r contributes r+1 everywhere; sum is world*(world+1)/2.
x = torch.full((1 << 20,), float(rank + 1), device=dev)
dist.all_reduce(x)
allreduce_ok = bool(torch.all(x == world * (world + 1) / 2).item())

# DDP training: same seed for the model, different data per rank.
torch.manual_seed(0)
model = DDP(nn.Sequential(nn.Linear(64, 128), nn.ReLU(), nn.Linear(128, 1)).to(dev),
            device_ids=[local_rank])
opt = torch.optim.SGD(model.parameters(), lr=0.05)
g = torch.Generator(device="cpu").manual_seed(1000 + rank)
w_true = torch.linspace(-1, 1, 64)
losses = []
for step in range(200):
    xb = torch.randn(256, 64, generator=g)
    yb = (xb @ w_true).unsqueeze(1)
    loss = nn.functional.mse_loss(model(xb.to(dev)), yb.to(dev))
    opt.zero_grad()
    loss.backward()
    opt.step()
    losses.append(loss.item())

flat = torch.cat([p.detach().flatten() for p in model.parameters()])
ref = flat.clone()
dist.broadcast(ref, 0)
same = torch.tensor([int(torch.equal(flat, ref))], device=dev)
dist.all_reduce(same, op=dist.ReduceOp.MIN)

# All-reduce bus bandwidth, 256 MB float32 (nccl-tests definition: 2(n-1)/n * size/time).
big = torch.ones(64 << 20, device=dev)
for _ in range(3):
    dist.all_reduce(big)
torch.cuda.synchronize()
reps = 10
t0 = time.time()
for _ in range(reps):
    dist.all_reduce(big)
torch.cuda.synchronize()
dt = (time.time() - t0) / reps
busbw = 2 * (world - 1) / world * big.numel() * 4 / dt / 1e9

if rank == 0:
    hosts = {h for h, _ in placement}
    gpus = {(h, u) for h, u in placement}
    print("world size %d, nodes %d, distinct GPUs %d" % (world, len(hosts), len(gpus)))
    print("allreduce sum: %s" % ("ok" if allreduce_ok else "WRONG"))
    print("loss decreased: %s" % ("yes" if losses[-1] < 0.1 * losses[0] else
                                  "no (%.4f -> %.4f)" % (losses[0], losses[-1])))
    print("weights identical on all ranks: %s" % ("yes" if same.item() else "NO"))
    print("busbw_GBps %.2f" % busbw)
dist.destroy_process_group()
