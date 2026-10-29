#!/bin/bash
#@ description: MPI inside a container: srun starts 4 container ranks across 2 nodes (hybrid model)
#@ param apptainer = apptainer
#@ param mpi_image =
#@ param srun_mpi = pmix
#@ requires-param: mpi_image
#@ modules: ${apptainer}
#@ nodes: 2
#@ tasks-per-node: 2
#@ time: 15
#@ local: no
#@ tags: container mpi

# mpi_image: a local .sif with an MPI built against PMI (pmix or pmi2, set srun_mpi to
# match) so Slurm can wire up ranks without an mpirun inside the container.
out=$(srun --mpi="$srun_mpi" apptainer -s exec "$mpi_image" ./mpi_hello)
echo "$out" | awk '{print $1, $2, $3, $4, $7, $8}' | sort -k2,2n
echo "distinct nodes: $(echo "$out" | awk '{print $6}' | sort -u | wc -l)"
