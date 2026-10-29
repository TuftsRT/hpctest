#!/bin/bash
#@ description: netCDF-Fortran: write a file and compare with ncdump
#@ param compiler = gcc
#@ param fc = gfortran
#@ param netcdf = netcdf-fortran
#@ modules: ${compiler} ${netcdf}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./simple_xy_wr
diff <(ncdump -n simple_xy test.nc) <(ncdump simple_xy.nc) && echo "files match"
