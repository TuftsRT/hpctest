#!/bin/bash
#@ description: GNU Scientific Library: Bessel function J0(5)
#@ param compiler = gcc
#@ param cc = gcc
#@ param gsl = gsl
#@ modules: ${compiler} ${gsl}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./gsl_bessel 5.0
