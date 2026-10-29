# Build step: runs inside the job after modules load (bash -e).
$cc -o ffttest fftw3-test.c -lfftw3 -lm
