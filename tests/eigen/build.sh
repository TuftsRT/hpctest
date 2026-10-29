# Build step: runs inside the job after modules load (bash -e).
# Eigen modules normally put include/eigen3 on CPATH; pkg-config covers the rest.
$cxx -O2 -o eigen_test eigen_test.cpp $(pkg-config --cflags eigen3 2>/dev/null || true)
