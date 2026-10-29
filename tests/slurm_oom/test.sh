#!/bin/bash
#@ description: a process exceeding the job's 1000 MB limit gets OOM-killed
#@ ntasks: 1
#@ mem: 1000M
#@ time: 5
#@ local: no
#@ stderr: ignore
#@ exit-code: any
#@ tags: scheduler

python3 -c '
import sys
blocks = []
for i in range(40):
    blocks.append(bytearray(100 * 1024 * 1024))
print("allocated 4000 MB without being killed")
'
rc=$?
if [ $rc -eq 137 ] || [ $rc -eq 9 ] || [ $rc -eq -9 ]; then echo "memory hog was killed (exit $rc)"
else echo "memory hog exited with $rc"; fi
