#!/bin/bash
#@ description: GNU parallel runs a task list with 2 job slots, keeping order
#@ param parallel = parallel
#@ modules: ${parallel}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 5
#@ tags: tool workflow

parallel --will-cite -j 2 --keep-order 'echo {} $(( {} * {} ))' ::: 1 2 3 4 5
parallel --will-cite -j 2 echo {1}-{2} ::: a b ::: x y | sort
seq 10 | parallel --will-cite -j 2 --pipe -N 5 'wc -l' | sort | uniq -c | awk '{print $1 " chunks of " $2}'
