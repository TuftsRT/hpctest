#!/bin/bash
#@ description: Apptainer --nv: the job's one GPU is visible and usable inside a container
#@ param apptainer = apptainer
#@ param image = docker://docker.io/library/alpine:3.20
#@ modules: ${apptainer}
#@ ntasks: 1
#@ gpus: 1
#@ time: 15
#@ tags: container gpu

# --nv binds the host driver and nvidia-smi into any image, so a plain image is enough.
export APPTAINER_CACHEDIR=$PWD/cache SINGULARITY_CACHEDIR=$PWD/cache
if [[ -f $image ]]; then sif=$image
elif apptainer -q pull img.sif "$image" > pull.log 2>&1; then sif=img.sif
else echo "pull $image: FAILED"; tail -5 pull.log; exit 0; fi
echo "GPUs inside: $(apptainer -s exec --nv "$sif" nvidia-smi -L 2>&1 | grep -c '^GPU ')"
apptainer -s exec --nv "$sif" nvidia-smi --query-gpu=memory.used --format=csv,noheader \
    >/dev/null 2>&1 && echo "driver query: ok" || echo "driver query: FAILED"
