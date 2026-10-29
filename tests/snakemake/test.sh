#!/bin/bash
#@ description: Snakemake runs a 5-job workflow with wildcards on 2 cores
#@ param snakemake = snakemake
#@ modules: ${snakemake}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 10
#@ tags: tool workflow

export XDG_CACHE_HOME=$PWD/.cache
snakemake --cores 2 --snakefile Snakefile > snakemake.log 2>&1 || { cat snakemake.log >&2; exit 1; }
echo "squares: $(cat sq_1.txt sq_2.txt sq_3.txt sq_4.txt | tr '\n' ' ')"
echo "total: $(cat total.txt)"
snakemake --cores 1 --snakefile Snakefile --dry-run 2>&1 | grep -qi 'nothing to be done' && echo "rerun: nothing to be done"
