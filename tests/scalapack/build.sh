# Build step: runs inside the job after modules load (bash -e).
mpif90 -o scalapack_test scalapack_test.f90 $scalapack_libs
