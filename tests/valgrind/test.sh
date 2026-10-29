#!/bin/bash
#@ description: Valgrind memcheck finds a leak and an invalid write
#@ param compiler = gcc
#@ param cc = gcc
#@ param valgrind = valgrind
#@ modules: ${compiler} ${valgrind}
#@ ntasks: 1
#@ time: 10
#@ tags: tool

valgrind --leak-check=full ./buggy > /dev/null 2> vg.log
# Drop the "==PID== " prefix and keep the lines that prove memcheck worked.
sed -n 's/^==[0-9]*== *//p' vg.log |
    grep -E '^Invalid write|definitely lost:|total heap usage|ERROR SUMMARY' | sed 's/ from [0-9]* contexts.*//'
