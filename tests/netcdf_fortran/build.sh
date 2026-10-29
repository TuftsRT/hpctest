# Build step: runs inside the job after modules load (bash -e).
$fc -o simple_xy_wr $(nf-config --fflags) simple_xy_wr.f90 $(nf-config --flibs)
