#!/bin/bash
#@ description: HMMER hmmsearch of a globin profile
#@ param hmmer = hmmer
#@ modules: ${hmmer}
#@ ntasks: 2
#@ time: 10
#@ tags: app bio

hmmsearch --cpu 2 globins4.hmm globins4.fa | grep -v '#'
