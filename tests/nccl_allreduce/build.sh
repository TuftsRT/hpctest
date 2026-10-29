# Build step: runs inside the job after modules load (bash -e).
# NCCL may live outside nvcc's default paths (e.g. NVHPC comm_libs/<cuda>/nccl-<ver>);
# take the newest copy built for this nvcc's CUDA version, else the newest of any.
root=$(dirname "$(dirname "$(command -v nvcc)")")
cver=$(nvcc --version | sed -n 's/.*release \([0-9]*\.[0-9]*\).*/\1/p')
libs=$(find "$root" "$root/../.." -name 'libnccl.so' 2>/dev/null | sort -rV)
lib=$(echo "$libs" | grep "/$cver/" | head -1)
[ -n "$lib" ] || lib=$(echo "$libs" | head -1)
flags=""
if [ -n "$lib" ]; then
    d=$(dirname "$lib")
    flags="-L$d -Xlinker -rpath=$d -I$d/../include"
fi
nvcc -O2 -Wno-deprecated-gpu-targets -o nccl_allreduce nccl_allreduce.cu $flags -lnccl
