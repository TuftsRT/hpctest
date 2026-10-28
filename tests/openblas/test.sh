#!/bin/bash
#@ description: OpenBLAS: CBLAS dgemm
#@ param compiler = gcc
#@ param cc = gcc
#@ param blas = openblas
#@ modules: ${compiler} ${blas}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./cblas
