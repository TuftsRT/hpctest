#!/bin/bash
#@ description: afterok dependencies: B waits for A; a job depending on a failed job is cancelled
#@ ntasks: 1
#@ time: 20
#@ local: no
#@ tags: scheduler

opts=(--parsable -J hpctest-sub -n1 -t 2 --mem=200M -o /dev/null
      ${SLURM_JOB_PARTITION:+-p "$SLURM_JOB_PARTITION"} ${SLURM_JOB_ACCOUNT:+-A "$SLURM_JOB_ACCOUNT"}
      ${SLURM_JOB_QOS:+-q "$SLURM_JOB_QOS"})
sub() { sbatch "${opts[@]}" "$@"; }
a=$(sub --wrap 'sleep 20; echo A > a.txt')
b=$(sub --dependency=afterok:$a --wrap 'cat a.txt > b.txt')
f=$(sub --wrap 'exit 1')
d=$(sub --dependency=afterok:$f --kill-on-invalid-dep=yes --wrap 'touch d.txt')
ids="$a,$b,$f,$d"
[[ $ids =~ ^[0-9]+,[0-9]+,[0-9]+,[0-9]+$ ]] || { echo "sbatch failed: $ids"; exit 0; }
trap 'scancel ${ids//,/ } 2>/dev/null' EXIT

while [[ -n $(squeue -h -j "$ids" -o %i 2>/dev/null) ]]; do sleep 10; done
echo "B ran after A finished: $([[ $(cat b.txt 2>/dev/null) == A ]] && echo yes || echo no)"
echo "job depending on a failed job ran: $([[ -e d.txt ]] && echo yes || echo no)"
for i in $(seq 12); do
    states=$(for j in $a $b $f $d; do sacct -n -X -P -j "$j" -o State | head -1 | cut -d' ' -f1; done | xargs)
    [[ $states != *PENDING* && $states != *RUNNING* ]] && break
    sleep 5
done
echo "sacct A B failed dependent: $states"
