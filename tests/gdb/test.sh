#!/bin/bash
#@ description: GDB runs a crashing program in batch mode and prints a backtrace
#@ param compiler = gcc
#@ param cc = gcc
#@ param gdb = gdb
#@ modules: ${compiler} ${gdb}
#@ ntasks: 1
#@ time: 10
#@ tags: tool

gdb -q -batch -nx -ex run -ex bt -ex 'print depth' ./crash > gdb.log 2>&1
grep -o 'received signal SIGSEGV' gdb.log | head -1
# Backtrace frames: function name only (addresses and paths differ by site).
grep -E '^#[0-9]' gdb.log | sed -E 's/^(#[0-9]+) +(0x[0-9a-f]+ in )?([A-Za-z_]+) .*/\1 \3/'
grep -E '^\$1 = ' gdb.log
