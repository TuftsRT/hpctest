#!/bin/bash
#@ description: Quantum ESPRESSO GPU build: pw.x relaxes a CO molecule on 1 GPU, same energy as the CPU test
#@ param mpi = openmpi
#@ param espresso = quantum-espresso+cuda
#@ param mpirun = mpirun
#@ modules: ${mpi} ${espresso}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ gpus: 1
#@ time: 15
#@ tags: app chem gpu

export OMP_NUM_THREADS=1
$mpirun -n 1 pw.x < co.rx.in > co.rx.out 2> pw.err || {
    tail -n 15 co.rx.out >&2; grep -vE '^-+$|^ *$' pw.err | head -n 5 >&2; exit 1; }
grep -qi 'GPU acceleration is ACTIVE' co.rx.out && echo "GPU acceleration: yes" || echo "GPU acceleration: no"
grep -E '^ *Final energy' co.rx.out
