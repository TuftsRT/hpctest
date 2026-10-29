# Build step: runs inside the job after modules load (bash -e).
nvcc -O2 -Wno-deprecated-gpu-targets -o cuda_p2p cuda_p2p.cu
