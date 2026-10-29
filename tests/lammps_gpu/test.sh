#!/bin/bash
#@ description: LAMMPS Lennard-Jones melt on 1 GPU (KOKKOS/CUDA): same answer as the CPU run, energy conserved
#@ param mpi = openmpi
#@ param lammps = lammps+cuda
#@ param lmp = lmp
#@ param launch = mpirun -n 1
#@ param accel = -k on g 1 -sf kk -pk kokkos newton on neigh half
#@ modules: ${mpi} ${lammps}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ gpus: 1
#@ time: 10
#@ baseline-by: gpu
#@ tags: app chem gpu

# accel: the command-line switches for this build's GPU package
# (KOKKOS: "-k on g 1 -sf kk", GPU package: "-sf gpu -pk gpu 1").
# launch: empty for a container build that brings its own MPI (mpi = empty too).
$launch $lmp $accel -in in.lj -log none > lmp.out 2>&1 || {
    # LAMMPS's own ERROR line last, after the MPI launcher's boilerplate.
    grep -vE '^ERROR' lmp.out | tail -n 15 >&2; grep -m3 '^ERROR' lmp.out >&2; exit 1; }
grep -qE 'will use up to [0-9]+ GPU|Kokkos::Cuda|KOKKOS package API: .*CUDA|using [0-9]+ GPU' lmp.out \
    && echo "GPU acceleration: yes" || echo "GPU acceleration: no"
# Same thermo extraction as tests/lammps; step 0 values match the CPU test exactly.
awk '$1 == "Step" { t = 1; next }
     /^Loop time/ { t = 0; print; next }
     t && $1 ~ /^[0-9]+$/ { if (n++ == 0) e0 = $5; s = $1; e = $5;
                            if ($1 == 0) printf "step 0: temp %.4f epair %.4f etotal %.4f press %.4f\n", $2, $3, $5, $6 }
     END { d = (e - e0) / e0; if (d < 0) d = -d
           printf "final step %d, relative energy drift %s\n", s, d < 0.01 ? "< 1%" : d }' lmp.out
