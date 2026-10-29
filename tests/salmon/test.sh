#!/bin/bash
#@ description: salmon index + quant of 100 reads from 3 transcripts (known counts 60/40/0)
#@ param salmon = salmon
#@ modules: ${salmon}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio

salmon index -t transcripts.fa -i idx -k 25 -p 2 > index.log 2>&1 || { tail index.log >&2; exit 1; }
salmon quant -i idx -l A -r reads.fq -p 2 --validateMappings -o quant > quant.log 2>&1 || { tail quant.log >&2; exit 1; }
awk 'NR > 1 { printf "%s reads %.1f TPM %.0f\n", $1, $5, $4 }' quant/quant.sf
grep -hE '"(num_processed|num_mapped|expected_format)"' quant/aux_info/meta_info.json quant/lib_format_counts.json \
    | tr -d ' ,"'
