#!/bin/bash
#@ description: Julia runs a hello-world script
#@ param julia = julia
#@ modules: ${julia}
#@ ntasks: 1
#@ time: 10
#@ tags: lang

julia test.jl
