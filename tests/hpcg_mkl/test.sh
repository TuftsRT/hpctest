#!/bin/bash
#@ description: Intel MKL HPCG, one MPI rank per socket, 60 s (GFLOP/s)
#@ param compiler = intel-oneapi-compilers
#@ param mkl = intel-oneapi-mkl
#@ param mpi = intel-oneapi-mpi
#@ modules: ${compiler} ${mkl} ${mpi}
#@ exclusive: yes
#@ time: 15
#@ tags: benchmark

B=${MKLROOT}/share/mkl/benchmarks/hpcg/hpcg_cpu/bin
flags=$(grep -m1 '^flags' /proc/cpuinfo)
if   [[ $flags == *avx512f* ]]; then HPCG_BIN=xhpcg_avx512
elif [[ $flags == *avx2* ]];    then HPCG_BIN=xhpcg_avx2
else                                 HPCG_BIN=xhpcg_sse42
fi
sockets=$(lscpu | awk '/^Socket\(s\):/{print $2}')
cores=$(lscpu | awk '/^Core\(s\) per socket:/{print $4}')
export OMP_NUM_THREADS=$cores
export KMP_AFFINITY=granularity=fine,compact,1,0
mpiexec -n $sockets -ppn $sockets $B/$HPCG_BIN -n192 -t60 > hpcg.log 2>&1
grep -h "^HPCG result is" hpcg.log | head -1
