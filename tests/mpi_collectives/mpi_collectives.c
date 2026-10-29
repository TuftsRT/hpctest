/* Data-correctness check of MPI point-to-point and collectives across nodes.
 * Every rank fills buffers with values derived from (rank, index), so a corrupted,
 * truncated or misrouted message shows up as a wrong count of bad elements.
 * Message sizes cross the eager/rendezvous thresholds of common transports. */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static double val(int rank, long i) { return rank * 1.0e6 + (double)(i % 999983); }

static void report(const char *name, long bad, MPI_Comm comm, int rank)
{
    long total = 0;
    MPI_Reduce(&bad, &total, 1, MPI_LONG, MPI_SUM, 0, comm);
    if (rank == 0)
        printf("%-10s %s\n", name, total ? "FAILED" : "ok");
    if (rank == 0 && total)
        printf("%-10s %ld bad elements\n", name, total);
}

int main(int argc, char **argv)
{
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    /* Ring exchange: 1 element .. 4 Mi doubles (32 MB). */
    long bad = 0;
    long maxn = 4L << 20;
    double *sbuf = malloc(maxn * sizeof(double)), *rbuf = malloc(maxn * sizeof(double));
    int right = (rank + 1) % size, left = (rank + size - 1) % size;
    for (long n = 1; n <= maxn; n *= 8) {
        for (long i = 0; i < n; i++) { sbuf[i] = val(rank, i); rbuf[i] = -1; }
        MPI_Sendrecv(sbuf, n, MPI_DOUBLE, right, 0, rbuf, n, MPI_DOUBLE, left, 0,
                     MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        for (long i = 0; i < n; i++) bad += rbuf[i] != val(left, i);
    }
    report("sendrecv", bad, MPI_COMM_WORLD, rank);

    /* Nonblocking all-to-all neighbour pattern with Isend/Irecv. */
    bad = 0;
    long m = 65536;
    double *sall = malloc((size_t)size * m * sizeof(double));
    double *rall = malloc((size_t)size * m * sizeof(double));
    MPI_Request *req = malloc(2 * size * sizeof(MPI_Request));
    for (int p = 0; p < size; p++)
        for (long i = 0; i < m; i++) sall[p * m + i] = val(rank, i + p);
    for (int p = 0; p < size; p++) {
        MPI_Irecv(rall + p * m, m, MPI_DOUBLE, p, 1, MPI_COMM_WORLD, &req[p]);
        MPI_Isend(sall + p * m, m, MPI_DOUBLE, p, 1, MPI_COMM_WORLD, &req[size + p]);
    }
    MPI_Waitall(2 * size, req, MPI_STATUSES_IGNORE);
    for (int p = 0; p < size; p++)
        for (long i = 0; i < m; i++) bad += rall[p * m + i] != val(p, i + rank);
    report("isend", bad, MPI_COMM_WORLD, rank);

    /* Bcast 32 MB from the last rank. */
    bad = 0;
    for (long i = 0; i < maxn; i++) rbuf[i] = rank == size - 1 ? val(size - 1, i) : 0;
    MPI_Bcast(rbuf, maxn, MPI_DOUBLE, size - 1, MPI_COMM_WORLD);
    for (long i = 0; i < maxn; i++) bad += rbuf[i] != val(size - 1, i);
    report("bcast", bad, MPI_COMM_WORLD, rank);

    /* Allreduce 1 Mi doubles: sum over ranks of (rank+1)*i is exact in FP64. */
    bad = 0;
    long r = 1L << 20;
    for (long i = 0; i < r; i++) sbuf[i] = (double)(rank + 1) * (i % 1024);
    MPI_Allreduce(sbuf, rbuf, r, MPI_DOUBLE, MPI_SUM, MPI_COMM_WORLD);
    double ranks = (double)size * (size + 1) / 2;
    for (long i = 0; i < r; i++) bad += rbuf[i] != ranks * (i % 1024);
    report("allreduce", bad, MPI_COMM_WORLD, rank);

    /* Alltoall 64 Ki doubles per pair. */
    bad = 0;
    MPI_Alltoall(sall, m, MPI_DOUBLE, rall, m, MPI_DOUBLE, MPI_COMM_WORLD);
    for (int p = 0; p < size; p++)
        for (long i = 0; i < m; i++) bad += rall[p * m + i] != val(p, i + rank);
    report("alltoall", bad, MPI_COMM_WORLD, rank);

    /* Allgather of each rank's host name: number of distinct nodes. */
    char host[MPI_MAX_PROCESSOR_NAME] = {0}, *hosts;
    int len;
    MPI_Get_processor_name(host, &len);
    hosts = calloc((size_t)size, MPI_MAX_PROCESSOR_NAME);
    MPI_Allgather(host, MPI_MAX_PROCESSOR_NAME, MPI_CHAR, hosts, MPI_MAX_PROCESSOR_NAME,
                  MPI_CHAR, MPI_COMM_WORLD);
    if (rank == 0) {
        int distinct = 0;
        for (int p = 0; p < size; p++) {
            int seen = 0;
            for (int q = 0; q < p; q++)
                seen |= !strcmp(hosts + p * MPI_MAX_PROCESSOR_NAME, hosts + q * MPI_MAX_PROCESSOR_NAME);
            distinct += !seen;
        }
        printf("ranks %d, nodes %d\n", size, distinct);
    }

    /* Split by node and check the shared-memory communicator size. */
    MPI_Comm node;
    int nsize;
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &node);
    MPI_Comm_size(node, &nsize);
    int nmin, nmax;
    MPI_Reduce(&nsize, &nmin, 1, MPI_INT, MPI_MIN, 0, MPI_COMM_WORLD);
    MPI_Reduce(&nsize, &nmax, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0)
        printf("ranks per node: min %d max %d\n", nmin, nmax);

    MPI_Comm_free(&node);
    MPI_Finalize();
    return 0;
}
