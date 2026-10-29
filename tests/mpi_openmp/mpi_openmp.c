/* Hybrid MPI + OpenMP: each rank runs OMP_NUM_THREADS threads; every thread reports the
 * CPU it runs on. With correct binding, no two threads on a node share a CPU. A classic
 * failure is mpirun binding each rank to one core, so all its threads share that core. */
#define _GNU_SOURCE
#include <mpi.h>
#include <omp.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    int provided, rank, size;
    MPI_Init_thread(&argc, &argv, MPI_THREAD_FUNNELED, &provided);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    int nthreads = omp_get_max_threads();
    int *cpus = malloc(nthreads * sizeof(int));
    double local = 0;
    #pragma omp parallel reduction(+:local)
    {
        double t0 = omp_get_wtime(), x = 0;
        while (omp_get_wtime() - t0 < 0.5) x += 1e-9;   /* keep every thread busy */
        cpus[omp_get_thread_num()] = sched_getcpu();
        local += x > 0 ? 1 : 0;
    }

    /* Per node: gather all (cpu) of all threads, count distinct. */
    MPI_Comm node;
    int nrank, nsize;
    MPI_Comm_split_type(MPI_COMM_WORLD, MPI_COMM_TYPE_SHARED, 0, MPI_INFO_NULL, &node);
    MPI_Comm_rank(node, &nrank);
    MPI_Comm_size(node, &nsize);
    int *all = malloc((size_t)nsize * nthreads * sizeof(int));
    MPI_Gather(cpus, nthreads, MPI_INT, all, nthreads, MPI_INT, 0, node);
    int shared = 0;
    if (nrank == 0)
        for (int i = 0; i < nsize * nthreads; i++)
            for (int j = 0; j < i; j++) shared += all[i] == all[j];
    int is_leader = nrank == 0, nodes = 0, shared_total = 0;
    MPI_Reduce(&is_leader, &nodes, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(&shared, &shared_total, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);

    double total = 0;
    MPI_Reduce(&local, &total, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    int tmin, tmax;
    MPI_Reduce(&nthreads, &tmin, 1, MPI_INT, MPI_MIN, 0, MPI_COMM_WORLD);
    MPI_Reduce(&nthreads, &tmax, 1, MPI_INT, MPI_MAX, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        printf("thread support funneled: %s\n", provided >= MPI_THREAD_FUNNELED ? "yes" : "no");
        printf("ranks %d on %d nodes, threads per rank %d..%d, threads total %.0f\n",
               size, nodes, tmin, tmax, total);
        printf("threads sharing a CPU: %d\n", shared_total);
    }
    MPI_Finalize();
    return 0;
}
