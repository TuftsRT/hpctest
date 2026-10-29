#!/bin/bash
#@ description: sacct records each step's state, exit code and peak memory (MaxRSS)
#@ ntasks: 1
#@ mem: 2000M
#@ time: 10
#@ local: no
#@ stderr: ignore
#@ tags: scheduler

srun -n1 true
srun -n1 bash -c 'exit 7'
# Hold 500 MB for longer than the accounting sample interval (JobAcctGatherFrequency, often 30 s).
srun -n1 python3 -c 'import time; b = bytearray(500 << 20); b[::4096] = b"x" * len(b[::4096]); time.sleep(45)'

for i in $(seq 24); do
    rows=$(sacct -n -P -j "$SLURM_JOB_ID" -o JobID,State,ExitCode,MaxRSS --units=M |
           grep -E "^$SLURM_JOB_ID\.[0-2]\|")
    [[ $(echo "$rows" | grep -c COMPLETED) -ge 2 && $(echo "$rows" | grep -c FAILED) -ge 1 ]] && break
    sleep 5
done
echo "$rows" | awk -F'|' -v j="$SLURM_JOB_ID" '
    $1 == j ".0" { print "step 0 (true):", $2, $3 }
    $1 == j ".1" { print "step 1 (exit 7):", $2, $3 }
    $1 == j ".2" { rss = $4 + 0; print "step 2 MaxRSS >= 450 MB:", (rss >= 450 ? "yes" : "no (" $4 ")") }'
