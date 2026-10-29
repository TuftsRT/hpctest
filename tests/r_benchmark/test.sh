#!/bin/bash
#@ description: R-benchmark-25 (total seconds, lower is better)
#@ param r = r
#@ modules: ${r}
#@ exclusive: yes
#@ time: 10
#@ stderr: ignore
#@ tags: benchmark

unset DISPLAY
R --slave --vanilla < R-25 | grep '^Total time' | awk '{print "total seconds", $NF}'
