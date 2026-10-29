#!/bin/bash
#@ description: Boost: filesystem, regex, program_options, date_time libraries
#@ param compiler = gcc
#@ param cxx = g++
#@ param boost = boost
#@ modules: ${compiler} ${boost}
#@ ntasks: 1
#@ time: 5
#@ tags: lib

./boost_hello --count 7
