#!/bin/bash
#@ description: Intel MKL shared-memory LINPACK (GFlops); N=40000 (~13 GB) by default
#@ param mkl = intel-oneapi-mkl
#@ param linpack_n = 40000
#@ modules: ${mkl}
#@ exclusive: yes
#@ time: 20
#@ tags: benchmark

# One thread per physical core, pinned.
cores=$(lscpu -p=CORE,SOCKET | grep -v '^#' | sort -u | wc -l)
export OMP_NUM_THREADS=$cores KMP_AFFINITY=granularity=fine,compact,1,0
B=${MKLROOT}/share/mkl/benchmarks/linpack
cat > lininput <<IN
hpctest LINPACK input
hpctest LINPACK input
1               # number of tests
$linpack_n      # problem sizes
$linpack_n      # leading dimensions
3               # times to run a test
4               # alignment value (in KBytes)
IN
$B/xlinpack_xeon64 lininput > linpack.log
grep -A1 "Maximal" linpack.log | tail -1 | awk '{print "Maximal GFlops: " $5}'
grep "Residual checks" linpack.log
