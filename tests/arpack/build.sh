# Build step: runs inside the job after modules load (bash -e).
$fc -O2 -o laplace_eig laplace_eig.f90 -larpack $blas_libs
