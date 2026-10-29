#!/bin/bash
#@ description: IQ-TREE 2 ML tree (GTR+G) from a 6-taxon alignment simulated on a known tree; topology must match
#@ param iqtree = iqtree
#@ param iqtree_cmd = iqtree2
#@ modules: ${iqtree}
#@ ntasks: 2
#@ time: 10
#@ tags: app bio

# aln.fa: 1000 sites simulated (Jukes-Cantor) on ((taxA,taxB),(taxC,taxD),(taxE,taxF))
$iqtree_cmd -s aln.fa -m GTR+G -T 2 -seed 1 --prefix run > iqtree.log 2>&1 || { tail iqtree.log >&2; exit 1; }
echo "splits:"
awk -f splits.awk run.treefile
# total tree length (sum of branch lengths); simulated value 0.75
awk '{ n = split($0, f, ":"); for (i = 2; i <= n; i++) s += f[i] + 0 } END { printf "tree length 0.6-0.9: %s\n", (s > 0.6 && s < 0.9) ? "yes" : "no (" s ")" }' run.treefile
