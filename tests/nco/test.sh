#!/bin/bash
#@ description: NCO operators (ncap2, ncwa, ncks, ncrename) on a netCDF file
#@ param nco = nco
#@ modules: ${nco}
#@ ntasks: 1
#@ time: 5
#@ tags: lib netcdf

# test.nc: int data(x=6, y=12) = 0..71
ncap2 -O -s 'data=double(data); total=data.total()' test.nc work.nc
ncks --trd -H -C -s 'total = %g\n' -v total work.nc | grep .
ncwa -O -a x,y work.nc avg.nc
ncks --trd -H -C -s 'mean = %.2f\n' -v data avg.nc | grep .
ncks -O -d x,1,2 -d y,0,2 test.nc sub.nc
echo "subset = $(ncks --trd -H -C -s '%d ' -v data sub.nc | tr -s ' \n' ' ')"
ncrename -O -v data,field sub.nc renamed.nc
ncks -m renamed.nc | grep -q 'field' && echo "rename ok"
