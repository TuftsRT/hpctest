#!/bin/bash
#@ description: MATLAB batch mode (also checks the license server)
#@ param matlab = matlab
#@ modules: ${matlab}
#@ ntasks: 1
#@ time: 15
#@ tags: lang license

matlab -batch "input" | grep -A 8 "Magic square"
