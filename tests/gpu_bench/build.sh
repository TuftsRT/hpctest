# Build step: runs inside the job after modules load (bash -e).
# cuBLAS may live outside nvcc's default paths (e.g. NVHPC math_libs); find it.
root=$(dirname "$(dirname "$(command -v nvcc)")")
lib=$(find "$root" "$root/../.." -name 'libcublas.so' -path '*lib64*' 2>/dev/null | head -1)
inc=$(find "$root" "$root/../.." -name 'cublas_v2.h' 2>/dev/null | head -1)
flags=""
[ -n "$lib" ] && flags="$flags -L$(dirname "$lib") -Xlinker -rpath=$(dirname "$lib")"
[ -n "$inc" ] && flags="$flags -I$(dirname "$inc")"
nvcc -O3 -arch=native -o gpu_bench gpu_bench.cu $flags -lcublas
