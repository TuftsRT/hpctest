#!/bin/bash
#@ description: samtools faidx, sort, index, region query, idxstats, flagstat
#@ param samtools = samtools
#@ modules: ${samtools}
#@ ntasks: 2
#@ time: 5
#@ tags: app bio

samtools faidx ref.fa
samtools faidx ref.fa chrA:101-130
samtools sort -@ 2 -o sorted.bam reads.sam
samtools index sorted.bam
echo "first positions: $(samtools view sorted.bam | head -3 | cut -f4 | tr '\n' ' ')"
echo "reads in chrA:1-200: $(samtools view -c sorted.bam chrA:1-200)"
samtools idxstats sorted.bam
samtools flagstat sorted.bam | grep -E 'in total|^[0-9]+ \+ [0-9]+ mapped \('
