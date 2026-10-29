#!/bin/bash
#@ description: MMseqs2 easy-search: 3 mutated proteins (90% identity) find their source, 1 random finds none
#@ param mmseqs2 = mmseqs2
#@ modules: ${mmseqs2}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

mmseqs easy-search queries.faa db.faa hits.tsv tmp --threads 2 --max-seqs 1 \
    --format-output query,target,pident > search.log 2>&1 || { tail search.log >&2; exit 1; }
# query, best hit, identity (rounded)
awk '{ printf "%s %s %.0f%%\n", $1, $2, $3 }' hits.tsv | sort
echo "queries without hits: $(grep '^>' queries.faa | tr -d '>' | grep -vxF -f <(cut -f1 hits.tsv) | tr '\n' ' ')"
