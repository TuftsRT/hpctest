# Build step: runs inside the job after modules load (bash -e).
nvcc -Wno-deprecated-gpu-targets -o vector_add vector_add.cu
