// CUDA-aware MPI: device pointers go straight into MPI calls (GPUDirect / UCX cuda
// transports). Each rank uses one GPU; data is generated and checked on the GPU.
// A non-CUDA-aware MPI typically segfaults here; a misconfigured one corrupts data.
#include <cstdio>
#include <cstdlib>
#include <cuda_runtime.h>
#include <mpi.h>
#if __has_include(<mpi-ext.h>)
#include <mpi-ext.h>
#endif

#define CK(x) do { cudaError_t e = (x); if (e != cudaSuccess) { \
    printf("CUDA error %s at %s:%d\n", cudaGetErrorString(e), __FILE__, __LINE__); \
    MPI_Abort(MPI_COMM_WORLD, 1); } } while (0)

__global__ void fill(double *p, long n, int rank)
{
    for (long i = blockIdx.x * (long)blockDim.x + threadIdx.x; i < n; i += (long)gridDim.x * blockDim.x)
        p[i] = rank * 1.0e7 + (double)i;
}

__global__ void check(const double *p, long n, int rank, double scale, unsigned long long *bad)
{
    for (long i = blockIdx.x * (long)blockDim.x + threadIdx.x; i < n; i += (long)gridDim.x * blockDim.x)
        if (p[i] != scale * (rank * 1.0e7 + (double)i)) atomicAdd(bad, 1ULL);
}

static long count_bad(const double *p, long n, int rank, double scale, unsigned long long *dbad)
{
    unsigned long long h;
    CK(cudaMemset(dbad, 0, sizeof h));
    check<<<512, 256>>>(p, n, rank, scale, dbad);
    CK(cudaMemcpy(&h, dbad, sizeof h, cudaMemcpyDeviceToHost));
    return (long)h;
}

static void report(const char *what, long bad, int rank)
{
    long total = 0;
    MPI_Reduce(&bad, &total, 1, MPI_LONG, MPI_SUM, 0, MPI_COMM_WORLD);
    if (rank == 0) printf("%s: %s\n", what, total ? "CORRUPT" : "ok");
}

int main(int argc, char **argv)
{
    MPI_Init(&argc, &argv);
    int rank, size, ndev;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Comm node;
    int lrank;
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &node);
    MPI_Comm_rank(node, &lrank);
    CK(cudaGetDeviceCount(&ndev));
    CK(cudaSetDevice(lrank % ndev));

#if defined(MPIX_CUDA_AWARE_SUPPORT) && MPIX_CUDA_AWARE_SUPPORT
    if (rank == 0) printf("MPI reports CUDA-aware: %s\n", MPIX_Query_cuda_support() ? "yes" : "no");
#endif

    const long N = 16L << 20;  // 16 Mi doubles = 128 MB per buffer
    double *sbuf, *rbuf;
    unsigned long long *dbad;
    CK(cudaMalloc(&sbuf, N * sizeof(double)));
    CK(cudaMalloc(&rbuf, N * sizeof(double)));
    CK(cudaMalloc(&dbad, sizeof *dbad));
    int right = (rank + 1) % size, left = (rank + size - 1) % size;

    // Ring sendrecv, small (eager) to large (rendezvous / GPUDirect RDMA) messages.
    long bad = 0;
    fill<<<512, 256>>>(sbuf, N, rank);
    CK(cudaDeviceSynchronize());
    for (long n = 1; n <= N; n *= 16) {
        CK(cudaMemset(rbuf, 0, n * sizeof(double)));
        MPI_Sendrecv(sbuf, n, MPI_DOUBLE, right, 0, rbuf, n, MPI_DOUBLE, left, 0,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        bad += count_bad(rbuf, n, left, 1.0, dbad);
    }
    report("sendrecv device buffers", bad, rank);

    // Allreduce on device buffers: every rank contributes 1.0*value(rank 0 pattern).
    fill<<<512, 256>>>(sbuf, N, 0);
    CK(cudaDeviceSynchronize());
    MPI_Allreduce(sbuf, rbuf, N, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    report("allreduce device buffers", count_bad(rbuf, N, 0, (double)size, dbad), rank);

    // Bcast from the last rank into a device buffer.
    if (rank == size - 1) { fill<<<512, 256>>>(rbuf, N, rank); CK(cudaDeviceSynchronize()); }
    else CK(cudaMemset(rbuf, 0, N * sizeof(double)));
    MPI_Bcast(rbuf, N, MPI_DOUBLE, size - 1, MPI_COMM_WORLD);
    report("bcast device buffers", count_bad(rbuf, N, size - 1, 1.0, dbad), rank);

    // Bandwidth of a 128 MB device-to-device transfer between rank 0 and rank 1.
    const int reps = 10;
    MPI_Barrier(MPI_COMM_WORLD);
    double t0 = MPI_Wtime();
    for (int r = 0; r < reps; r++) {
        if (rank == 0) MPI_Send(sbuf, N, MPI_DOUBLE, 1, 1, MPI_COMM_WORLD);
        else if (rank == 1) MPI_Recv(rbuf, N, MPI_DOUBLE, 0, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    }
    MPI_Barrier(MPI_COMM_WORLD);
    double t = MPI_Wtime() - t0;

    char host[MPI_MAX_PROCESSOR_NAME];
    int len, distinct = 0;
    MPI_Get_processor_name(host, &len);
    int leader = lrank == 0;
    MPI_Reduce(&leader, &distinct, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        printf("ranks %d on %d nodes\n", size, distinct);
        printf("d2d_GBps %.2f\n", reps * N * sizeof(double) / t / 1e9);
    }
    MPI_Finalize();
    return 0;
}
