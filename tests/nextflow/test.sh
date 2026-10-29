#!/bin/bash
#@ description: Nextflow runs a local pipeline (4 tasks + reduce) offline
#@ param nextflow = nextflow
#@ modules: ${nextflow}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ mem: 4G
#@ time: 15
#@ tags: tool workflow

# Offline: no update checks or plugin downloads; keep the work dir in the test dir.
export NXF_OFFLINE=true NXF_ANSI_LOG=false NXF_DISABLE_CHECK_LATEST=true
nextflow -q run main.nf -w "$PWD/work" > nf.out 2> nf.err || { cat nf.out nf.err >&2; exit 1; }
grep "^sum of squares" nf.out
echo "task dirs: $(find work -name .exitcode | wc -l)"
