#!/bin/bash
#@ description: MEGAHIT de novo assembly of simulated reads from a 5 kb genome; contig must match it exactly
#@ param megahit = megahit
#@ modules: ${megahit}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

awk -f mkreads.awk genome.fa > reads.fq
echo "reads: $(awk 'NR % 4 == 1' reads.fq | wc -l)"
megahit -r reads.fq -t 2 -m 2000000000 -o asm > megahit.log 2>&1 || { tail megahit.log >&2; exit 1; }
awk -f compare_contigs.awk genome.fa asm/final.contigs.fa
