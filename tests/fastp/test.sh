#!/bin/bash
#@ description: fastp adapter trimming + quality filtering of 100 reads (30 with adapter, 20 low quality)
#@ param fastp = fastp
#@ modules: ${fastp}
#@ ntasks: 2
#@ time: 5
#@ tags: app bio

fastp -i reads.fq -o trimmed.fq -w 2 -G --adapter_sequence AGATCGGAAGAGCACACGTCTGAACTCCAGTCA \
      -j report.json -h report.html 2> fastp.log || { cat fastp.log >&2; exit 1; }
grep -oE '"(passed_filter_reads|low_quality_reads|too_short_reads|adapter_trimmed_reads|adapter_trimmed_bases)": *[0-9]+' report.json \
    | tr -d '" '
echo "reads written: $(awk 'NR % 4 == 2' trimmed.fq | wc -l), bases: $(awk 'NR % 4 == 2 { n += length($0) } END { print n }' trimmed.fq)"
