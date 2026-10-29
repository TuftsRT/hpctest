// GPU health benchmark: memory bandwidth, host<->device bandwidth, FP32 and
// FP16-tensor-core GEMM throughput. Prints one "name value" line per metric.
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <algorithm>
#include <cuda_runtime.h>
#include <cuda_fp16.h>
#include <cublas_v2.h>

#define CK(x) do { cudaError_t e = (x); if (e != cudaSuccess) { \
    fprintf(stderr, "CUDA error %s at %s:%d\n", cudaGetErrorString(e), __FILE__, __LINE__); \
    exit(1); } } while (0)
#define CB(x) do { cublasStatus_t s = (x); if (s != CUBLAS_STATUS_SUCCESS) { \
    fprintf(stderr, "cuBLAS error %d at %s:%d\n", (int)s, __FILE__, __LINE__); exit(1); } } while (0)

__global__ void triad(float *a, const float *b, const float *c, float s, size_t n)
{
    for (size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x; i < n;
         i += (size_t)gridDim.x * blockDim.x)
        a[i] = b[i] + s * c[i];
}

__global__ void fill(float *x, float v, size_t n)
{
    for (size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x; i < n;
         i += (size_t)gridDim.x * blockDim.x)
        x[i] = v;
}

__global__ void fill_half(__half *x, float v, size_t n)
{
    for (size_t i = blockIdx.x * (size_t)blockDim.x + threadIdx.x; i < n;
         i += (size_t)gridDim.x * blockDim.x)
        x[i] = __float2half(v);
}

// Best (minimum) time in ms of `reps` runs of f, after one warm-up.
template <typename F> static float best_ms(F f, int reps)
{
    cudaEvent_t t0, t1;
    CK(cudaEventCreate(&t0));
    CK(cudaEventCreate(&t1));
    f();
    CK(cudaDeviceSynchronize());
    float best = 1e30f;
    for (int r = 0; r < reps; r++) {
        CK(cudaEventRecord(t0));
        f();
        CK(cudaEventRecord(t1));
        CK(cudaEventSynchronize(t1));
        float ms;
        CK(cudaEventElapsedTime(&ms, t0, t1));
        best = std::min(best, ms);
    }
    return best;
}

int main()
{
    cudaDeviceProp p;
    CK(cudaGetDeviceProperties(&p, 0));
    printf("device: %s (sm_%d%d, %.0f GB)\n", p.name, p.major, p.minor,
           p.totalGlobalMem / 1e9);
    int blocks = p.multiProcessorCount * 8, threads = 256;

    // 1. Device memory bandwidth: triad over 3 x 1 GiB arrays (reads b, c; writes a).
    size_t n = (size_t)1 << 28;
    float *a, *b, *c;
    CK(cudaMalloc(&a, n * sizeof(float)));
    CK(cudaMalloc(&b, n * sizeof(float)));
    CK(cudaMalloc(&c, n * sizeof(float)));
    fill<<<blocks, threads>>>(b, 1.0f, n);
    fill<<<blocks, threads>>>(c, 2.0f, n);
    float ms = best_ms([&] { triad<<<blocks, threads>>>(a, b, c, 3.0f, n); }, 10);
    CK(cudaGetLastError());
    float check;
    CK(cudaMemcpy(&check, a + n / 2, sizeof(float), cudaMemcpyDeviceToHost));
    if (check != 7.0f) { fprintf(stderr, "triad result wrong: %f\n", check); return 1; }
    printf("triad_GBps %.0f\n", 3.0 * n * sizeof(float) / (ms / 1e3) / 1e9);

    // 2. Host -> device and device -> host with pinned memory (256 MiB).
    size_t bytes = (size_t)256 << 20;
    void *h;
    CK(cudaMallocHost(&h, bytes));
    ms = best_ms([&] { CK(cudaMemcpy(a, h, bytes, cudaMemcpyHostToDevice)); }, 5);
    printf("h2d_GBps %.1f\n", bytes / (ms / 1e3) / 1e9);
    ms = best_ms([&] { CK(cudaMemcpy(h, a, bytes, cudaMemcpyDeviceToHost)); }, 5);
    printf("d2h_GBps %.1f\n", bytes / (ms / 1e3) / 1e9);
    CK(cudaFreeHost(h));
    CK(cudaFree(a)); CK(cudaFree(b)); CK(cudaFree(c));

    // 3. GEMM throughput, m = n = k = 8192.
    int m = 8192;
    size_t mm = (size_t)m * m;
    double flop = 2.0 * m * (double)m * m;
    cublasHandle_t hb;
    CB(cublasCreate(&hb));
    float one = 1.0f, zero = 0.0f;

    float *A, *B, *C;
    CK(cudaMalloc(&A, mm * sizeof(float)));
    CK(cudaMalloc(&B, mm * sizeof(float)));
    CK(cudaMalloc(&C, mm * sizeof(float)));
    fill<<<blocks, threads>>>(A, 0.5f, mm);
    fill<<<blocks, threads>>>(B, 0.25f, mm);
    CB(cublasSetMathMode(hb, CUBLAS_PEDANTIC_MATH));     // true FP32, no TF32
    ms = best_ms([&] { CB(cublasSgemm(hb, CUBLAS_OP_N, CUBLAS_OP_N, m, m, m, &one, A, m,
                                      B, m, &zero, C, m)); }, 5);
    CK(cudaMemcpy(&check, C + mm / 3, sizeof(float), cudaMemcpyDeviceToHost));
    if (check != 0.125f * m) { fprintf(stderr, "sgemm result wrong: %f\n", check); return 1; }
    printf("sgemm_TFLOPS %.1f\n", flop / (ms / 1e3) / 1e12);
    CK(cudaFree(A)); CK(cudaFree(B));

    __half *Ah, *Bh;
    CK(cudaMalloc(&Ah, mm * sizeof(__half)));
    CK(cudaMalloc(&Bh, mm * sizeof(__half)));
    fill_half<<<blocks, threads>>>(Ah, 0.5f, mm);
    fill_half<<<blocks, threads>>>(Bh, 0.25f, mm);
    CB(cublasSetMathMode(hb, CUBLAS_DEFAULT_MATH));
    ms = best_ms([&] { CB(cublasGemmEx(hb, CUBLAS_OP_N, CUBLAS_OP_N, m, m, m, &one,
                                       Ah, CUDA_R_16F, m, Bh, CUDA_R_16F, m, &zero,
                                       C, CUDA_R_32F, m, CUBLAS_COMPUTE_32F,
                                       CUBLAS_GEMM_DEFAULT)); }, 5);
    CK(cudaMemcpy(&check, C + mm / 3, sizeof(float), cudaMemcpyDeviceToHost));
    if (check != 0.125f * m) { fprintf(stderr, "fp16 gemm result wrong: %f\n", check); return 1; }
    printf("fp16_gemm_TFLOPS %.1f\n", flop / (ms / 1e3) / 1e12);
    CK(cudaFree(Ah)); CK(cudaFree(Bh)); CK(cudaFree(C));
    CB(cublasDestroy(hb));
    return 0;
}
