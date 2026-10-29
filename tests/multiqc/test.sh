#!/bin/bash
#@ description: MultiQC parses samtools flagstat and cutadapt reports; aggregated values checked
#@ param multiqc = multiqc
#@ modules: ${multiqc}
#@ ntasks: 1
#@ mem: 2G
#@ time: 10
#@ tags: app bio python

multiqc -q -c multiqc_config.yaml -o report inputs > multiqc.log 2>&1 || { tail multiqc.log >&2; exit 1; }
ls report/multiqc_report.html > /dev/null || exit 1
# print the named columns of a MultiQC data table, rows sorted by sample
cols() { awk -F'\t' -v want="$2" 'NR == 1 { for (i = 1; i <= NF; i++) c[$i] = i; n = split(want, w, " "); next }
         { line = $1; for (i = 1; i <= n; i++) line = line " " w[i] "=" $(c[w[i]]); print line }' "$1" | sort; }
cols report/multiqc_data/multiqc_samtools_flagstat.txt "total_passed mapped_passed duplicates_passed"
cols report/multiqc_data/multiqc_cutadapt.txt "r_processed r_with_adapters r_too_short r_written bp_written"
