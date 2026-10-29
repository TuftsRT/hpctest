#!/bin/bash
#@ description: STREAM memory bandwidth (MB/s), whole node, one thread per core
#@ param compiler = gcc
#@ param cc = gcc
#@ exclusive: yes
#@ nodes: 1
#@ time: 10
#@ modules: ${compiler}
#@ tags: benchmark

cores=$(lscpu -p=CORE,SOCKET | grep -v '^#' | sort -u | wc -l)
export OMP_NUM_THREADS=$cores OMP_PROC_BIND=spread OMP_PLACES=cores
./stream > stream.log
awk '/^(Copy|Scale|Add|Triad):/ {sub(":", "", $1); printf "%s %d\n", $1, $2}' stream.log
