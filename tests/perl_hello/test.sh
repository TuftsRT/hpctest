#!/bin/bash
#@ description: Perl interpreter with core modules (List::Util, POSIX, Data::Dumper, JSON::PP)
#@ param perl = perl
#@ modules: ${perl}
#@ ntasks: 1
#@ time: 5
#@ tags: lang

perl test.pl
