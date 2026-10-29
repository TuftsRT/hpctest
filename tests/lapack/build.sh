# Build step: runs inside the job after modules load (bash -e).
$fc -o lapack_test lapack_test.f90 $lapack_libs
