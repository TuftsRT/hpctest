// GPU-to-GPU copies within one node: peer access when the GPUs support it (NVLink or
// PCIe P2P), otherwise staged through the host. The data is checked on the receiving
// GPU, and the copy bandwidth is reported for each direction.
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>

#define CK(x) do { cudaError_t e = (x); if (e != cudaSuccess) { \
    printf("CUDA error %s at %s:%d\n", cudaGetErrorString(e), __FILE__, __LINE__); exit(1); } } while (0)

__global__ void fill(unsigned *p, size_t n, unsigned seed)
{
    for (size_t i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += gridDim.x * blockDim.x)
        p[i] = (unsigned)i * 2654435761u + seed;
}

__global__ void check(const unsigned *p, size_t n, unsigned seed, unsigned long long *bad)
{
    for (size_t i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += gridDim.x * blockDim.x)
        if (p[i] != (unsigned)i * 2654435761u + seed) atomicAdd(bad, 1ULL);
}

int main()
{
    int n;
    CK(cudaGetDeviceCount(&n));
    printf("GPUs visible: %d\n", n);
    if (n < 2) return 1;

    const size_t N = 64 << 20;  // 64 Mi uint32 = 256 MB
    const size_t bytes = N * sizeof(unsigned);
    unsigned *buf[2];
    unsigned long long *bad[2];
    for (int d = 0; d < 2; d++) {
        CK(cudaSetDevice(d));
        CK(cudaMalloc(&buf[d], bytes));
        CK(cudaMalloc(&bad[d], sizeof(unsigned long long)));
    }
    int p01, p10;
    CK(cudaDeviceCanAccessPeer(&p01, 0, 1));
    CK(cudaDeviceCanAccessPeer(&p10, 1, 0));
    bool peer = p01 && p10;
    if (peer) {
        CK(cudaSetDevice(0)); CK(cudaDeviceEnablePeerAccess(1, 0));
        CK(cudaSetDevice(1)); CK(cudaDeviceEnablePeerAccess(0, 0));
    }
    // Volatile: depends on the node's GPU topology. Goes to stderr-free stdout line.
    printf("peer access: %s\n", peer ? "yes" : "no");

    for (int src = 0; src < 2; src++) {
        int dst = 1 - src;
        unsigned seed = 12345u + src;
        CK(cudaSetDevice(src));
        fill<<<1024, 256>>>(buf[src], N, seed);
        CK(cudaDeviceSynchronize());

        cudaEvent_t t0, t1;
        CK(cudaEventCreate(&t0)); CK(cudaEventCreate(&t1));
        const int reps = 10;
        CK(cudaMemcpyPeer(buf[dst], dst, buf[src], src, bytes));  // warm-up
        CK(cudaEventRecord(t0));
        for (int r = 0; r < reps; r++)
            CK(cudaMemcpyPeerAsync(buf[dst], dst, buf[src], src, bytes));
        CK(cudaEventRecord(t1));
        CK(cudaEventSynchronize(t1));
        float ms;
        CK(cudaEventElapsedTime(&ms, t0, t1));

        CK(cudaSetDevice(dst));
        CK(cudaMemset(bad[dst], 0, sizeof(unsigned long long)));
        check<<<1024, 256>>>(buf[dst], N, seed, bad[dst]);
        unsigned long long nbad;
        CK(cudaMemcpy(&nbad, bad[dst], sizeof nbad, cudaMemcpyDeviceToHost));
        printf("GPU%d -> GPU%d: %s\n", src, dst, nbad ? "CORRUPT" : "data ok");
        printf("GPU%d_to_GPU%d_GBps %.1f\n", src, dst, reps * bytes / (ms * 1e6));
    }

    // Kernel on GPU1 reading GPU0 memory directly (only with peer access).
    if (peer) {
        CK(cudaSetDevice(0));
        fill<<<1024, 256>>>(buf[0], N, 777u);
        CK(cudaDeviceSynchronize());
        CK(cudaSetDevice(1));
        CK(cudaMemset(bad[1], 0, sizeof(unsigned long long)));
        check<<<1024, 256>>>(buf[0], N, 777u, bad[1]);
        unsigned long long nbad;
        CK(cudaMemcpy(&nbad, bad[1], sizeof nbad, cudaMemcpyDeviceToHost));
        printf("GPU1 kernel reads GPU0 memory: %s\n", nbad ? "CORRUPT" : "data ok");
    }
    return 0;
}
