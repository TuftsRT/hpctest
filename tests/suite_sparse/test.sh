#!/bin/bash
#@ description: SuiteSparse from C: UMFPACK and KLU solve a 5x5 system, CHOLMOD a 100x100 SPD system
#@ param compiler = gcc
#@ param cc = gcc
#@ param suitesparse = suite-sparse
#@ modules: ${compiler} ${suitesparse}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./sparse_solve
