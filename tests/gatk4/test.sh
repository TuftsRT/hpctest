#!/bin/bash
#@ description: GATK4 SortSam + HaplotypeCaller finds a known hom-alt and a het SNP
#@ param gatk4 = gatk4
#@ modules: ${gatk4}
#@ ntasks: 2
#@ mem: 6G
#@ time: 15
#@ tags: app bio java

gatk() { command gatk --java-options "-Xmx2g -XX:ParallelGCThreads=2" "$@" >> gatk.log 2>&1 || { tail -20 gatk.log >&2; exit 1; }; }
gatk CreateSequenceDictionary -R ref.fa
gatk SortSam -I reads.sam -O sorted.bam --SORT_ORDER coordinate --CREATE_INDEX true
gatk CountReads -I sorted.bam
grep -E '^Tool returned:' -A1 gatk.log | tail -1 | sed 's/^/reads in BAM: /'
gatk HaplotypeCaller -R ref.fa -I sorted.bam -O calls.vcf
# CHROM POS REF ALT GT
grep -v '^#' calls.vcf | awk '{ split($10, f, ":"); print $1, $2, $4, $5, f[1] }'
