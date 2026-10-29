#!/bin/bash
#@ description: kallisto index + single-end quant of 100 reads from 3 transcripts (known counts 60/40/0)
#@ param kallisto = kallisto
#@ modules: ${kallisto}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

kallisto index -i idx transcripts.fa > index.log 2>&1 || { tail index.log >&2; exit 1; }
kallisto quant -i idx -o quant --single -l 75 -s 1 -t 2 reads.fq > quant.log 2>&1 || { tail quant.log >&2; exit 1; }
awk 'NR > 1 { printf "%s est_counts %.1f TPM %.0f\n", $1, $4, $5 }' quant/abundance.tsv
grep -E '"n_(processed|pseudoaligned)"' quant/run_info.json | tr -d ' \t,"'
