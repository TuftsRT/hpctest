#!/bin/bash
#@ description: Picard SortSam, MarkDuplicates (8 known duplicates of 48 reads), alignment metrics, ValidateSamFile
#@ param picard = picard
#@ modules: ${picard}
#@ ntasks: 2
#@ mem: 4G
#@ time: 10
#@ tags: app bio java

picard() { command picard -Xmx2g "$@" >> picard.log 2>&1 || { tail -20 picard.log >&2; exit 1; }; }
picard SortSam I=reads.sam O=sorted.bam SORT_ORDER=coordinate
picard MarkDuplicates I=sorted.bam O=marked.bam M=dup_metrics.txt
picard CollectAlignmentSummaryMetrics R=ref.fa I=marked.bam O=aln_metrics.txt
picard ValidateSamFile R=ref.fa I=marked.bam MODE=SUMMARY O=validate.txt
# metrics tables: header line, then values; print name=value pairs we know the answer to
metric() { awk -v want="$2" -F'\t' 'p && NF > 1 { n = split(want, w, " "); for (i = 1; i <= n; i++) printf "%s=%s ", w[i], v[w[i]] = $(c[w[i]]); print ""; exit }
          /^(LIBRARY|CATEGORY)\t/ { for (i = 1; i <= NF; i++) c[$i] = i; p = 1 }' "$1"; }
metric dup_metrics.txt "UNPAIRED_READS_EXAMINED UNPAIRED_READ_DUPLICATES PERCENT_DUPLICATION"
metric aln_metrics.txt "TOTAL_READS PF_READS_ALIGNED PF_ALIGNED_BASES PF_MISMATCH_RATE"
echo "flagged duplicates:" $(command picard ViewSam I=marked.bam ALIGNMENT_STATUS=All PF_STATUS=All 2>/dev/null \
    | awk '!/^@/ && and($2, 1024) { print $1 }' | sort)
cat validate.txt
