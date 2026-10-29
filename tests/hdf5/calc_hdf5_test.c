#include "hdf5.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define FILENAME "calc_hdf5_test.h5"
#define DATASET_NAME "calculation_results"
#define NX 10  // Number of rows
#define NY 5   // Number of columns

int main() {
    hid_t file_id, dataset_id, dataspace_id;  // HDF5 handles
    hsize_t dims[2] = {NX, NY};              // Dataset dimensions
    herr_t status;

    // Allocate memory for the dataset
    double data[NX][NY];

    // Perform some calculations and populate the dataset
    printf("Performing calculations...\n");
    for (int i = 0; i < NX; i++) {
        for (int j = 0; j < NY; j++) {
            data[i][j] = sin(i + 1.0) * cos(j + 1.0);  // Example: sine-cosine calculation
        }
    }

    // Print the calculated data
    printf("Calculated Data:\n");
    for (int i = 0; i < NX; i++) {
        for (int j = 0; j < NY; j++) {
            printf("%.6f ", data[i][j]);
        }
        printf("\n");
    }

    // Create a new HDF5 file
    printf("\nCreating HDF5 file: %s\n", FILENAME);
    file_id = H5Fcreate(FILENAME, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT);

    // Create the dataspace for the dataset
    dataspace_id = H5Screate_simple(2, dims, NULL);

    // Create the dataset
    printf("Writing dataset: %s\n", DATASET_NAME);
    dataset_id = H5Dcreate(file_id, DATASET_NAME, H5T_NATIVE_DOUBLE, dataspace_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT);

    // Write the calculated data to the dataset
    status = H5Dwrite(dataset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, data);

    // Close resources after writing
    H5Dclose(dataset_id);
    H5Sclose(dataspace_id);
    H5Fclose(file_id);

    // Reopen the file and dataset to read back the data
    printf("\nReading and verifying dataset: %s\n", DATASET_NAME);
    file_id = H5Fopen(FILENAME, H5F_ACC_RDONLY, H5P_DEFAULT);
    dataset_id = H5Dopen(file_id, DATASET_NAME, H5P_DEFAULT);

    double read_data[NX][NY];
    status = H5Dread(dataset_id, H5T_NATIVE_DOUBLE, H5S_ALL, H5S_ALL, H5P_DEFAULT, read_data);

    // Print the read-back data
    printf("Read-Back Data:\n");
    for (int i = 0; i < NX; i++) {
        for (int j = 0; j < NY; j++) {
            printf("%.6f ", read_data[i][j]);
        }
        printf("\n");
    }

    // Verify the data
    printf("\nVerifying calculated data...\n");
    int correct = 1;
    for (int i = 0; i < NX; i++) {
        for (int j = 0; j < NY; j++) {
            if (fabs(data[i][j] - read_data[i][j]) > 1e-6) {
                correct = 0;
                printf("Mismatch at [%d][%d]: expected %.6f, got %.6f\n", i, j, data[i][j], read_data[i][j]);
            }
        }
    }

    if (correct) {
        printf("Data verification successful!\n");
    } else {
        printf("Data verification failed.\n");
    }

    // Close resources
    H5Dclose(dataset_id);
    H5Fclose(file_id);

    return 0;
}
