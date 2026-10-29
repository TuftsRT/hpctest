/* MPI-IO on the shared file system: every rank writes its own interleaved blocks of
 * one file with a collective write, then reads back the blocks written by a rank on
 * another node and verifies them. Catches missing locking/coherence on the parallel
 * file system and broken ROMIO/OMPIO drivers. */
#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>

#define BLOCK (1 << 18)   /* doubles per block: 2 MB */
#define NBLOCKS 8         /* blocks per rank */

static double val(int rank, int b, long i) { return rank * 1.0e7 + b * 1.0e6 + i; }

int main(int argc, char **argv)
{
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    double *buf = malloc(BLOCK * sizeof(double));
    MPI_File fh;
    MPI_File_open(MPI_COMM_WORLD, "mpiio.dat", MPI_MODE_CREATE | MPI_MODE_WRONLY,
                  MPI_INFO_NULL, &fh);
    /* Block b of rank r goes to file block b*size + r (round-robin interleaving). */
    for (int b = 0; b < NBLOCKS; b++) {
        for (long i = 0; i < BLOCK; i++) buf[i] = val(rank, b, i);
        MPI_Offset off = ((MPI_Offset)b * size + rank) * BLOCK * sizeof(double);
        MPI_File_write_at_all(fh, off, buf, BLOCK, MPI_DOUBLE, MPI_STATUS_IGNORE);
    }
    MPI_File_close(&fh);

    MPI_Offset fsize = 0;
    MPI_File_open(MPI_COMM_WORLD, "mpiio.dat", MPI_MODE_RDONLY, MPI_INFO_NULL, &fh);
    MPI_File_get_size(fh, &fsize);
    /* Read the blocks of the rank half-way around: with ranks filled node by node,
     * that rank is on another node. */
    int other = (rank + size / 2) % size;
    long bad = 0;
    for (int b = 0; b < NBLOCKS; b++) {
        MPI_Offset off = ((MPI_Offset)b * size + other) * BLOCK * sizeof(double);
        MPI_File_read_at_all(fh, off, buf, BLOCK, MPI_DOUBLE, MPI_STATUS_IGNORE);
        for (long i = 0; i < BLOCK; i++) bad += buf[i] != val(other, b, i);
    }
    MPI_File_close(&fh);

    long total = 0;
    MPI_Reduce(&bad, &total, 1, MPI_LONG, MPI_SUM, 0, MPI_COMM_WORLD);
    if (rank == 0) {
        long expect = (long)size * NBLOCKS * BLOCK * sizeof(double);
        printf("file size %s\n", fsize == expect ? "ok" : "WRONG");
        printf("read back by other node: %s", total ? "FAILED" : "ok\n");
        if (total) printf(" (%ld bad doubles)\n", total);
        MPI_File_delete("mpiio.dat", MPI_INFO_NULL);
    }
    MPI_Finalize();
    return 0;
}
