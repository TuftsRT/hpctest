#!/bin/bash
#@ description: Fortran compiler builds and runs a small program
#@ param compiler = gcc
#@ param fc = gfortran
#@ modules: ${compiler}
#@ ntasks: 1
#@ time: 5
#@ tags: compiler

./hello
