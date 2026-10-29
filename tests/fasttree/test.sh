#!/bin/bash
#@ description: FastTree GTR tree from a 6-taxon alignment simulated on a known tree; topology must match
#@ param fasttree = fasttree
#@ modules: ${fasttree}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

# aln.fa: 1000 sites simulated (Jukes-Cantor) on ((taxA,taxB),(taxC,taxD),(taxE,taxF))
FastTree -nt -gtr aln.fa > tree.nwk 2> fasttree.log || { tail fasttree.log >&2; exit 1; }
echo "splits:"
awk -f splits.awk tree.nwk
# total tree length (sum of branch lengths); simulated value 0.75
awk '{ n = split($0, f, ":"); for (i = 2; i <= n; i++) s += f[i] + 0 } END { printf "tree length 0.6-0.9: %s\n", (s > 0.6 && s < 0.9) ? "yes" : "no (" s ")" }' tree.nwk
