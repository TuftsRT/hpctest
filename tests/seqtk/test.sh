#!/bin/bash
#@ description: seqtk FASTQ->FASTA, reverse complement, composition, trimming, subseq, quality masking
#@ param seqtk = seqtk
#@ modules: ${seqtk}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

# container wrappers may print informational lines on stderr: keep them in a log
seqtk() { command seqtk "$@" 2>> seqtk.log; }
echo "== fasta"; seqtk seq -A reads.fq
echo "== revcomp r1"; seqtk seq -r reads.fq | sed -n 2p
echo "== comp (name len A C G T)"; seqtk comp reads.fq | cut -f1-6
echo "== trim 2 left, 3 right"; seqtk trimfq -b 2 -e 3 reads.fq | awk 'NR % 4 == 2'
echo "== subseq r2"; echo r2 > names.txt; seqtk subseq reads.fq names.txt
echo "== mask Q<20"; seqtk seq -q 20 -n N reads.fq | awk 'NR % 4 == 2'
echo "== reads >= 18 bp: $(seqtk seq -L 18 reads.fq | awk 'NR % 4 == 1' | wc -l)"
