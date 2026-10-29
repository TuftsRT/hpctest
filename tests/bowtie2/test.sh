#!/bin/bash
#@ description: bowtie2-build and bowtie2 align 200 reads; per-contig counts
#@ param bowtie2 = bowtie2
#@ modules: ${bowtie2}
#@ ntasks: 2
#@ time: 10
#@ tags: app bio

bowtie2-build --threads 2 -q ref.fa ref
bowtie2 -p 2 --no-unal -x ref -U reads.fq -S aln.sam 2> align.log
grep 'overall alignment rate' align.log
echo "per-contig: $(grep -v '^@' aln.sam | cut -f3 | sort | uniq -c | awk '{printf "%s=%s ", $2, $1}')"
echo "reverse strand: $(grep -v '^@' aln.sam | awk 'and($2, 16)' | wc -l)"
