#!/bin/bash
#@ description: Mathematica solves an equation in script mode (checks the license)
#@ param mathematica = mathematica
#@ modules: ${mathematica}
#@ ntasks: 1
#@ time: 15
#@ tags: lang license

math -script quadratic.m
