# Build step: runs inside the job after modules load (bash -e).
# Compile with the container's own MPI so it matches the library used at run time.
apptainer -s exec "$mpi_image" mpicc -o mpi_hello mpi_hello.c
