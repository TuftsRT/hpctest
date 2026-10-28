#!/bin/bash
#@ description: srun launches 2 tasks on each of 4 nodes
#@ nodes: 4
#@ tasks-per-node: 2
#@ time: 5
#@ local: no
#@ tags: scheduler

srun hostname | sort | uniq -c | awk '{print $1}' | sort | uniq -c | awk '{print $1 " nodes with " $2 " tasks"}'
