# Build step: runs inside the job after modules load (bash -e).
$mpicc -O2 -o mpi_io mpi_io.c
