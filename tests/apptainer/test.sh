#!/bin/bash
#@ description: Apptainer: get an image, run it, same user inside, bind mounts both ways, exit code
#@ param apptainer = apptainer
#@ param image = docker://docker.io/library/alpine:3.20
#@ param bind_paths =
#@ modules: ${apptainer}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 15
#@ tags: container

# image: a registry URI (pulled into the job directory, which also tests registry access
# from compute nodes) or a local .sif path. bind_paths: extra directories users bind,
# e.g. project storage. Apptainer binds the job directory ($PWD) by default.
export APPTAINER_CACHEDIR=$PWD/cache SINGULARITY_CACHEDIR=$PWD/cache
run() { apptainer -s exec "$@"; }

if [[ -f $image ]]; then sif=$image
elif apptainer -q pull img.sif "$image" > pull.log 2>&1; then sif=img.sif
else echo "pull $image: FAILED"; tail -5 pull.log; exit 0; fi
echo "image: ok"

if run "$sif" grep -q '^ID=' /etc/os-release; then echo "runs: ok"; else echo "runs: FAILED"; fi

inside=$(run "$sif" id -u)
[[ $inside == "$(id -u)" ]] && echo "same user inside: ok" || echo "uid inside: '$inside', outside: $(id -u)"

echo "from host" > host.txt
if [[ $(run "$sif" cat "$PWD/host.txt") == "from host" ]] &&
   run "$sif" sh -c "echo from container > '$PWD/ctr.txt'" &&
   [[ $(cat ctr.txt 2>/dev/null) == "from container" ]]; then
    echo "job directory bind: ok"
else
    echo "job directory bind: FAILED"
fi
for p in $bind_paths; do
    run -B "$p" "$sif" ls "$p" >/dev/null 2>&1 || echo "bind $p: FAILED"
done

run "$sif" sh -c 'exit 3'
echo "exit code passed through: $?"
