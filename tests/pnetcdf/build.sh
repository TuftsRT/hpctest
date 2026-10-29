# Build step: runs inside the job after modules load (bash -e).
PNC=$(pnetcdf-config --prefix 2>/dev/null || echo "$PARALLEL_NETCDF_HOME")
mpicc -o pnetcdf-write-standard -I$PNC/include pnetcdf-write-standard.c -L$PNC/lib -lpnetcdf
