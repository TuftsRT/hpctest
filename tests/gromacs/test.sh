#!/bin/bash
#@ description: GROMACS 1000 MD steps of water on one GPU
#@ param gromacs = gromacs
#@ param gmx = gmx_mpi
#@ param mpirun = mpirun
#@ modules: ${gromacs}
#@ ntasks: 4
#@ gpus: 1
#@ time: 15
#@ tags: app gpu

out=$($mpirun -n 4 $gmx -quiet mdrun -deffnm MD_5NM_WATER -nsteps 1000 2>&1) || {
    echo "$out" >&2; echo "mdrun failed" >&2; exit 1; }
echo "$out" | grep -E '^Using 4 MPI processes|GPU selected for this run|^Performance'
