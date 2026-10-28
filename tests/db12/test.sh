#!/bin/bash
#@ description: DIRAC DB12 CPU benchmark, one Python process per CPU (score per CPU)
#@ exclusive: yes
#@ time: 15
#@ tags: benchmark

python3 DIRACbenchmark.py $(nproc)
