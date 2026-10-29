# Build step: runs inside the job after modules load (bash -e).
# The CUDA-enabled MPI module is expected to bring nvcc (or load ${cuda} as well).
nvcc -O2 -Wno-deprecated-gpu-targets -ccbin "$(command -v $mpicxx)" -o cuda_mpi cuda_mpi.cu
