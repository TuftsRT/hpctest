#!/bin/bash
#@ description: DIAMOND makedb + blastp: 3 mutated proteins (90% identity) find their source, 1 random finds none
#@ param diamond = diamond
#@ modules: ${diamond}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

diamond makedb --in db.faa -d db -p 2 > makedb.log 2>&1 || { tail makedb.log >&2; exit 1; }
diamond blastp -q queries.faa -d db -o hits.tsv -p 2 --max-target-seqs 1 \
    --outfmt 6 qseqid sseqid pident length > blastp.log 2>&1 || { tail blastp.log >&2; exit 1; }
# query, best hit, identity (rounded), alignment length
awk '{ printf "%s %s %.0f%% %s\n", $1, $2, $3, $4 }' hits.tsv | sort
echo "queries without hits: $(grep '^>' queries.faa | tr -d '>' | grep -vxF -f <(cut -f1 hits.tsv) | tr '\n' ' ')"
