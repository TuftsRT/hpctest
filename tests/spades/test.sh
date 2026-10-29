#!/bin/bash
#@ description: SPAdes (--isolate, with read error correction) assembly of a 5 kb genome; contig must match it exactly
#@ param spades = spades
#@ modules: ${spades}
#@ ntasks: 2
#@ mem: 6G
#@ time: 15
#@ tags: app bio

awk -f mkreads.awk genome.fa > reads.fq
echo "reads: $(awk 'NR % 4 == 1' reads.fq | wc -l)"
spades.py --isolate -s reads.fq -t 2 -m 4 -o asm > spades.log 2>&1 || { tail -20 asm/spades.log >&2; exit 1; }
awk -f compare_contigs.awk genome.fa asm/contigs.fasta
