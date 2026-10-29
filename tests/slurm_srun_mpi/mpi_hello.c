#include <mpi.h>
#include <stdio.h>

/* Each rank reports itself and the result of an allreduce over all ranks. */
int main(int argc, char **argv)
{
    int rank, size, len, sum = 0;
    char host[MPI_MAX_PROCESSOR_NAME];
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(host, &len);
    MPI_Allreduce(&rank, &sum, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD);
    printf("rank %d of %d host %s allreduce %d\n", rank, size, host, sum);
    MPI_Finalize();
    return 0;
}
