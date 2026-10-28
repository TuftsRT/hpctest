#!/bin/bash
#@ description: R evaluates an expression
#@ param r = r
#@ modules: ${r}
#@ ntasks: 1
#@ time: 5
#@ tags: lang quick

unset DISPLAY
R -q --vanilla --no-save < input_test
