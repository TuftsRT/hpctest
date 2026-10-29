#!/bin/bash
#@ description: minimap2 maps forward and reverse-strand reads to a reference
#@ param minimap2 = minimap2
#@ modules: ${minimap2}
#@ ntasks: 2
#@ time: 5
#@ tags: app bio

# PAF columns: query, length, start, end, strand, target, length, start, end, matches, block, MAPQ
minimap2 -t 2 -c ref.fa reads.fa 2>/dev/null | cut -f1-11 | sort
