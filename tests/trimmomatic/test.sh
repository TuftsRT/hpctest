#!/bin/bash
#@ description: Trimmomatic SE sliding-window quality trimming (60 good, 20 bad-tail, 20 bad reads)
#@ param trimmomatic = trimmomatic
#@ modules: ${trimmomatic}
#@ ntasks: 2
#@ mem: 4G
#@ time: 5
#@ tags: app bio java

trimmomatic SE -threads 2 -phred33 reads.fq trimmed.fq SLIDINGWINDOW:4:20 MINLEN:36 > trim.log 2>&1 \
    || { cat trim.log >&2; exit 1; }
grep -E '^Input Reads|Completed successfully' trim.log
echo "lengths (count length):"
awk 'NR % 4 == 2 { print length($0) }' trimmed.fq | sort -n | uniq -c | awk '{ print $1, $2 }'
