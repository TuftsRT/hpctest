#!/bin/bash
#@ description: RAxML-NG (MPI build) ML tree search, 4 ranks on 2 nodes; known 6-taxon topology
#@ param raxml = raxml-ng-mpi
#@ param raxml_cmd = raxml-ng-mpi
#@ param srun_mpi = pmix
#@ modules: ${raxml}
#@ nodes: 2
#@ tasks-per-node: 2
#@ time: 15
#@ local: no
#@ tags: app bio mpi

# aln.fa: 1000 sites simulated (Jukes-Cantor) on ((taxA,taxB),(taxC,taxD),(taxE,taxF))
# a 6-taxon search takes seconds: a hang must not burn the whole time limit
timeout 300 srun --mpi="$srun_mpi" $raxml_cmd --search --msa aln.fa --model GTR+G --threads 1 --seed 1 \
    --prefix run > raxml.log 2>&1 || { echo "raxml-ng exit status $?" >&2; grep -m3 -E 'ERROR|Assertion' raxml.log >&2; exit 1; }
grep -m1 -oE 'MPI \([0-9]+ ranks\)' raxml.log
echo "splits:"
awk -f splits.awk run.raxml.bestTree
# total tree length (sum of branch lengths); simulated value 0.75
awk '{ n = split($0, f, ":"); for (i = 2; i <= n; i++) s += f[i] + 0 } END { printf "tree length 0.6-0.9: %s\n", (s > 0.6 && s < 0.9) ? "yes" : "no (" s ")" }' run.raxml.bestTree
