# Build step: runs inside the job after modules load (bash -e).
$mpicc -O2 -o osu_scatter osu_scatter.c
