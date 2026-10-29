#!/bin/bash
#@ description: Eigen (header-only C++): QR solve and symmetric eigenvalues
#@ param compiler = gcc
#@ param cxx = g++
#@ param eigen = eigen
#@ modules: ${compiler} ${eigen}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./eigen_test
