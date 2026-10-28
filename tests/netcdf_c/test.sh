#!/bin/bash
#@ description: netCDF-C: write a file and compare with ncdump against a reference
#@ param compiler = gcc
#@ param cc = gcc
#@ param netcdf = netcdf-c
#@ modules: ${compiler} ${netcdf}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./simple_xy_wr
diff <(ncdump -n simple_xy test.nc) <(ncdump simple_xy.nc) && echo "files match"
