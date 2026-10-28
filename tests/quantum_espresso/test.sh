#!/bin/bash
#@ description: Quantum ESPRESSO pw.x relaxes a CO molecule on 4 MPI ranks
#@ param compiler = gcc
#@ param mpi = openmpi
#@ param espresso = quantum-espresso
#@ param mpirun = mpirun
#@ modules: ${compiler} ${mpi} ${espresso}
#@ ntasks: 4
#@ time: 15
#@ tags: app chem

export OMP_NUM_THREADS=1
$mpirun -n 4 pw.x < co.rx.in > co.rx.out
grep -E '^ *(Number of MPI processes|Final energy)' co.rx.out
