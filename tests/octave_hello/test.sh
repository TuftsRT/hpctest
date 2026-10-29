#!/bin/bash
#@ description: GNU Octave runs a script without a display
#@ param octave = octave
#@ modules: ${octave}
#@ ntasks: 1
#@ time: 10
#@ tags: lang

unset DISPLAY
octave -q --no-window-system input_test.m
