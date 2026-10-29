#!/bin/bash
#@ description: FastQC (Java) quality report for 200 reads
#@ param fastqc = fastqc
#@ modules: ${fastqc}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

fastqc -q -t 2 --extract -o . reads.fq > fastqc.log
grep -E '^(Total Sequences|Sequence length|%GC)' reads_fastqc/fastqc_data.txt
cut -f1,2 reads_fastqc/summary.txt | grep -E 'Basic Statistics'
