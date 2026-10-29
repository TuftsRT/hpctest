#!/bin/bash
#@ description: RDMA (InfiniBand/RoCE) ports are up at the expected rate
#@ param rdma_min_ports = 1
#@ param rdma_rate =
#@ ntasks: 1
#@ time: 5
#@ tags: node network

# rdma_min_ports: active ports each node must have. rdma_rate: minimum Gb/s of every
# active port (e.g. 100 for HDR100/100GbE; empty = any). Down ports are ignored, since
# many nodes have an unused second port.
if ! command -v ibstat >/dev/null 2>&1; then
    echo "ibstat not found (install infiniband-diags)"; exit 0
fi
ibstat | awk -v min="$rdma_min_ports" -v rate="$rdma_rate" '
    /^CA /           { ca = $2; gsub(/\047/, "", ca) }
    /^\tPort [0-9]+:/ { port = ca ":" $2; sub(/:$/, "", port) }
    /State:/ && !/Physical/ { state[port] = $2 }
    /Rate:/          { speed[port] = $2 }
    END {
        for (p in state) if (state[p] == "Active") {
            n++
            if (rate != "" && speed[p] + 0 < rate + 0) {
                printf "port %s: rate %s Gb/s < %s\n", p, speed[p], rate; slow++
            }
        }
        if (n < min) printf "active RDMA ports: %d (need %d)\n", n, min
        else if (!slow) print "active RDMA ports: ok"
    }'
