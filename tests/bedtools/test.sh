#!/bin/bash
#@ description: bedtools intersect, merge, complement and coverage
#@ param bedtools = bedtools
#@ modules: ${bedtools}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

echo "intersect -wa -wb:"
bedtools intersect -a a.bed -b b.bed -wa -wb
echo "merge:"
bedtools merge -i a.bed -c 4 -o collapse
echo "complement:"
bedtools complement -i a.bed -g genome.txt
echo "coverage:"
bedtools coverage -a a.bed -b b.bed | cut -f4-
