#!/bin/bash
#@ description: Prodigal (meta mode) finds 4 planted genes (both strands, with RBS) at their exact coordinates
#@ param prodigal = prodigal
#@ modules: ${prodigal}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

# contig.fa: AT-rich stop-dense filler with 4 ORFs (ATG...TAA) preceded by AGGAGG:
#   413-1318 +, 1719-2474 -, 2899-3954 +, 4355-4960 -
prodigal -q -p meta -i contig.fa -f gff -o genes.gff -a proteins.faa 2> prodigal.log || { cat prodigal.log >&2; exit 1; }
# start end strand start-codon RBS-motif
grep -v '^#' genes.gff | awk -F'\t' '{ match($9, /start_type=[^;]*/); s = substr($9, RSTART + 11, RLENGTH - 11)
                                       match($9, /rbs_motif=[^;]*/); r = substr($9, RSTART + 10, RLENGTH - 10)
                                       print $4, $5, $7, s, r }'
echo "protein lengths: $(awk '/^>/ { if (s) print length(s); s = ""; next } { s = s $0 } END { print length(s) }' proteins.faa | tr '\n' ' ')"
