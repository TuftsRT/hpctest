// NCCL all-reduce across every GPU visible to the job (one process, one thread).
// Checks the sum is right, then reports bus bandwidth as nccl-tests does:
// busbw = bytes / time * 2 (n - 1) / n.
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <cuda_runtime.h>
#include <nccl.h>

#define CK(x) do { cudaError_t e = (x); if (e != cudaSuccess) { \
    fprintf(stderr, "CUDA error %s at %s:%d\n", cudaGetErrorString(e), __FILE__, __LINE__); \
    exit(1); } } while (0)
#define NK(x) do { ncclResult_t r = (x); if (r != ncclSuccess) { \
    fprintf(stderr, "NCCL error %s at %s:%d\n", ncclGetErrorString(r), __FILE__, __LINE__); \
    exit(1); } } while (0)

__global__ void fill(float *x, float v, size_t n)
{
    for (size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x; i < n;
         i += (size_t)gridDim.x * blockDim.x)
        x[i] = v;
}

static void allreduce(std::vector<ncclComm_t> &comms, std::vector<float *> &buf,
                      std::vector<cudaStream_t> &st, size_t n)
{
    NK(ncclGroupStart());
    for (size_t g = 0; g < comms.size(); g++)
        NK(ncclAllReduce(buf[g], buf[g], n, ncclFloat, ncclSum, comms[g], st[g]));
    NK(ncclGroupEnd());
    for (size_t g = 0; g < comms.size(); g++) {
        CK(cudaSetDevice(g));
        CK(cudaStreamSynchronize(st[g]));
    }
}

int main()
{
    int ng;
    CK(cudaGetDeviceCount(&ng));
    if (ng < 2) { printf("need at least 2 GPUs, job sees %d\n", ng); return 0; }
    size_t n = (size_t)64 << 20;                      // 64 Mi floats = 256 MiB per GPU
    std::vector<ncclComm_t> comms(ng);
    std::vector<float *> buf(ng);
    std::vector<cudaStream_t> st(ng);
    NK(ncclCommInitAll(comms.data(), ng, NULL));
    for (int g = 0; g < ng; g++) {
        CK(cudaSetDevice(g));
        CK(cudaStreamCreate(&st[g]));
        CK(cudaMalloc(&buf[g], n * sizeof(float)));
        fill<<<256, 256, 0, st[g]>>>(buf[g], g + 1.0f, n);
    }
    allreduce(comms, buf, st, n);                      // warm-up + correctness
    float want = ng * (ng + 1) / 2.0f;
    for (int g = 0; g < ng; g++) {
        float got[2];
        CK(cudaSetDevice(g));
        CK(cudaMemcpy(&got[0], buf[g], sizeof(float), cudaMemcpyDeviceToHost));
        CK(cudaMemcpy(&got[1], buf[g] + n - 1, sizeof(float), cudaMemcpyDeviceToHost));
        if (got[0] != want || got[1] != want) {
            printf("GPU %d: sum %g, expected %g\n", g, got[0], want);
            return 1;
        }
    }
    printf("allreduce sum: ok\n");

    int reps = 20;
    CK(cudaSetDevice(0));
    cudaEvent_t t0, t1;
    CK(cudaEventCreate(&t0));
    CK(cudaEventCreate(&t1));
    CK(cudaEventRecord(t0, st[0]));
    for (int r = 0; r < reps; r++)
        allreduce(comms, buf, st, n);
    CK(cudaSetDevice(0));
    CK(cudaEventRecord(t1, st[0]));
    CK(cudaEventSynchronize(t1));
    float ms;
    CK(cudaEventElapsedTime(&ms, t0, t1));
    double sec = ms / 1e3 / reps, bytes = n * sizeof(float);
    printf("busbw_GBps %.1f\n", bytes / sec / 1e9 * 2.0 * (ng - 1) / ng);

    for (int g = 0; g < ng; g++) {
        CK(cudaSetDevice(g));
        CK(cudaFree(buf[g]));
        NK(ncclCommDestroy(comms[g]));
    }
    return 0;
}
