#!/bin/bash
#@ description: ARPACK-NG (Fortran): 4 largest eigenvalues of a 1-D Laplacian vs the analytic values
#@ param compiler = gcc
#@ param fc = gfortran
#@ param arpack = arpack-ng
#@ param blas_libs = -lopenblas
#@ modules: ${compiler} ${arpack}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./laplace_eig
