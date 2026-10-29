#!/bin/bash
#@ description: LAPACK dgesv/dsyev from Fortran (netlib, OpenBLAS or MKL via params)
#@ param compiler = gcc
#@ param fc = gfortran
#@ param lapack = netlib-lapack
#@ param lapack_libs = -llapack -lblas
#@ modules: ${compiler} ${lapack}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./lapack_test
