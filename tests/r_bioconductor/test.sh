#!/bin/bash
#@ description: R + Bioconductor: Biostrings, GenomicRanges, edgeR and DESeq2 known answers
#@ param rbio = r-bioinformatics
#@ modules: ${rbio}
#@ ntasks: 1
#@ mem: 4G
#@ time: 10
#@ tags: app bio lang

Rscript bioc.R
