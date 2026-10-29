#!/bin/bash
#@ description: Python distribution with NumPy: arrays, stats, linear algebra
#@ param python = anaconda
#@ modules: ${python}
#@ ntasks: 1
#@ time: 10
#@ tags: lang

python test.py
