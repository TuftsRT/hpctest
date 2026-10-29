#!/bin/bash
#@ description: hisat2-build + align 100 RNA-seq reads; 20 spliced over intron chr1:1301-2000
#@ param hisat2 = hisat2
#@ modules: ${hisat2}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

hisat2-build -q -p 2 genome.fa idx 2> build.log || { cat build.log >&2; exit 1; }
hisat2 -p 2 -x idx -U reads.fq -S aln.sam 2> align.log || { cat align.log >&2; exit 1; }
sed 's/^ *//' align.log
# intron = from end of the first M block to the start of the next one
grep -v '^@' aln.sam | awk '$6 ~ /^[0-9]+M[0-9]+N[0-9]+M$/ {
        split($6, a, /[MN]/); s = $4 + a[1]; n[s "-" s + a[2] - 1]++ }
    END { for (k in n) print "intron chr1:" k ", reads " n[k] }'
