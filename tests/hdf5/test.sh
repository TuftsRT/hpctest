#!/bin/bash
#@ description: HDF5: write a dataset with h5cc and read it back
#@ param hdf5 = hdf5
#@ modules: ${hdf5}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./calc_hdf5_test
