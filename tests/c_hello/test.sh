#!/bin/bash
#@ description: C compiler builds and runs a hello-world program
#@ param compiler = gcc
#@ param cc = gcc
#@ modules: ${compiler}
#@ ntasks: 1
#@ time: 5
#@ tags: compiler quick

./hello
