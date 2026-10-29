#!/bin/bash
#@ description: gnuplot renders a PNG without a display
#@ param gnuplot = gnuplot
#@ modules: ${gnuplot}
#@ ntasks: 1
#@ time: 5
#@ tags: app

unset DISPLAY
gnuplot -c gnuplot-sin_png.plt
file output.png
