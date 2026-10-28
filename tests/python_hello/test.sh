#!/bin/bash
#@ description: Python interpreter runs a pure-Python matrix product
#@ param python = python
#@ modules: ${python}
#@ ntasks: 1
#@ time: 5
#@ tags: lang quick

python3 matrix.py
