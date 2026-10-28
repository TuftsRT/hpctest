#!/bin/bash
#@ description: FFTW3: compile and compute the FFT of a sine wave
#@ param compiler = gcc
#@ param cc = gcc
#@ param fftw = fftw
#@ modules: ${compiler} ${fftw}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./ffttest
