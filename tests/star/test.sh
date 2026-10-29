#!/bin/bash
#@ description: STAR genomeGenerate + align 100 RNA-seq reads (20 spliced over a GT/AG intron)
#@ param star = star
#@ modules: ${star}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

mkdir -p idx
STAR --runMode genomeGenerate --runThreadN 2 --genomeDir idx --genomeFastaFiles genome.fa \
     --genomeSAindexNbases 5 --outFileNamePrefix idx/ > idx.log || { cat idx.log >&2; exit 1; }
STAR --runThreadN 2 --genomeDir idx --readFilesIn reads.fq --outFileNamePrefix aln/ \
     --outSAMtype SAM > aln.log || { cat aln.log >&2; exit 1; }
grep -E 'input reads|Uniquely mapped reads (number|%)|splices: (Total|GT/AG)|mismatches' aln/Log.final.out \
    | sed 's/^ *//; s/ *|\t/: /'
echo "junctions (chr start end strand motif annotated unique multi):"
cut -f1-8 aln/SJ.out.tab
echo "reads with N in CIGAR: $(grep -v '^@' aln/Aligned.out.sam | awk '$6 ~ /N/' | wc -l)"
