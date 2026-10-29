#!/bin/bash
#@ description: GPU health: no uncorrectable ECC errors, no pending page retirement, full PCIe link width
#@ ntasks: 1
#@ gpus: 1
#@ time: 5
#@ tags: gpu node

# Checks the GPU this job was given; run it per GPU model (or per node) to cover a cluster.
# PCIe *generation* drops when the GPU idles, so only the link width is compared.
q() { nvidia-smi -i 0 --query-gpu="$1" --format=csv,noheader,nounits 2>/dev/null | tr -d ' '; }
name=$(nvidia-smi -i 0 --query-gpu=name --format=csv,noheader)
[[ -n $name ]] || { echo "nvidia-smi cannot query the GPU"; exit 0; }

ecc=$(q ecc.errors.uncorrected.volatile.total)
if [[ $ecc =~ ^[0-9]+$ && $ecc -gt 0 ]]; then     # N/A: ECC off or unsupported
    echo "uncorrectable ECC errors: $ecc since boot ($name)"
else
    echo "uncorrectable ECC errors: ok"
fi

pending=$(q retired_pages.pending)
remap=$(q remapped_rows.pending)                # A100 and newer
if [[ $pending == Yes || $remap == Yes ]]; then
    echo "memory retirement pending: reset the GPU ($name)"
else
    echo "memory retirement pending: ok"
fi

cur=$(q pcie.link.width.current); max=$(q pcie.link.width.max)
if [[ $cur =~ ^[0-9]+$ && $max =~ ^[0-9]+$ && $cur -lt $max ]]; then
    echo "PCIe link width: x$cur of x$max ($name)"
else
    echo "PCIe link width: ok"
fi
