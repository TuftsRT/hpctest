#!/bin/bash
#@ description: cutadapt 3' adapter + quality trimming of 100 reads (30 with adapter, 20 low quality)
#@ param cutadapt = cutadapt
#@ modules: ${cutadapt}
#@ ntasks: 2
#@ time: 5
#@ tags: app bio

cutadapt -j 2 -q 20 -m 25 -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA -o trimmed.fq reads.fq > report.txt \
    || { cat report.txt >&2; exit 1; }
grep -E '^(Total reads processed|Reads with adapters|Reads that were too short|Reads written|Quality-trimmed|Total written)' report.txt \
    | sed 's/  */ /g'
echo "read lengths (count length): $(awk 'NR % 4 == 2 { print length($0) }' trimmed.fq | sort -n | uniq -c | awk '$1 > 1 { printf "%s:%s ", $1, $2 }')"
