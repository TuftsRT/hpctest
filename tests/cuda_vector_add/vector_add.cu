#include <iostream>
#include <cuda_runtime.h>

// CUDA kernel for vector addition
__global__ void vector_add(float *a, float *b, float *c, int n) {
    int index = threadIdx.x + blockIdx.x * blockDim.x;
    if (index < n) {
        c[index] = a[index] + b[index];
    }
}

int main() {
    int n = 100;  // Size of vectors
    float *a, *b, *c;  // Host pointers
    float *d_a, *d_b, *d_c;  // Device pointers

    size_t bytes = n * sizeof(float);

    // Allocate memory on host
    a = (float*)malloc(bytes);
    b = (float*)malloc(bytes);
    c = (float*)malloc(bytes);

    // Initialize vectors on host
    for (int i = 0; i < n; i++) {
        a[i] = float(i);
        b[i] = float(i) * 2.0f;
    }

    // Allocate memory on device
    cudaMalloc(&d_a, bytes);
    cudaMalloc(&d_b, bytes);
    cudaMalloc(&d_c, bytes);

    // Copy vectors from host to device
    cudaMemcpy(d_a, a, bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_b, b, bytes, cudaMemcpyHostToDevice);

    // Define block size and grid size
    int block_size = 256;
    int grid_size = (n + block_size - 1) / block_size;

    // Launch the kernel
    vector_add<<<grid_size, block_size>>>(d_a, d_b, d_c, n);

    // Copy result from device to host
    cudaMemcpy(c, d_c, bytes, cudaMemcpyDeviceToHost);

    // Print the result
    std::cout << "Result: ";
    for (int i = 0; i < n; i++) {
        std::cout << c[i] << " ";
    }
    std::cout << std::endl;

    // Free memory
    free(a);
    free(b);
    free(c);
    cudaFree(d_a);
    cudaFree(d_b);
    cudaFree(d_c);

    return 0;
}
