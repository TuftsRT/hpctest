# Build step: runs inside the job after modules load (bash -e).
$mpicc -O2 $ompflag -o mpi_openmp mpi_openmp.c
