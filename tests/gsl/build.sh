# Build step: runs inside the job after modules load (bash -e).
$cc -o gsl_bessel gsl_bessel.c $(gsl-config --cflags --libs)
