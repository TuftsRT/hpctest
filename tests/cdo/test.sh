#!/bin/bash
#@ description: CDO generates, remaps, averages and writes netCDF fields
#@ param cdo = cdo
#@ modules: ${cdo}
#@ ntasks: 1
#@ time: 5
#@ tags: lib netcdf

echo "fldmean   = $(cdo -s outputf,%g -fldmean -const,3.5,r36x18)"
echo "remapbil  = $(cdo -s outputf,%g -fldmean -remapbil,r72x36 -const,2,r36x18)"
cdo -s -f nc setname,t -for,1,10 series.nc
echo "timesteps = $(cdo -s ntime series.nc)"
echo "timmean   = $(cdo -s outputf,%g -timmean series.nc)"
echo "variable  = $(cdo -s showname series.nc | tr -d ' ')"
