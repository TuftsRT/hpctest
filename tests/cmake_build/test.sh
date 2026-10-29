#!/bin/bash
#@ description: CMake configures, builds and ctest-runs a C project with a static library
#@ param compiler = gcc
#@ param cc = gcc
#@ param cmake = cmake
#@ modules: ${compiler} ${cmake}
#@ ntasks: 1
#@ cpus-per-task: 2
#@ time: 10
#@ tags: compiler tool

./build/cmake_hello 7
cd build && ctest 2>&1 | grep -E 'tests passed'
