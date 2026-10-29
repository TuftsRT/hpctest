#!/bin/bash
#@ description: Subread featureCounts: gene counts from a SAM with spliced reads (SAF annotation, known answers)
#@ param subread = subread
#@ modules: ${subread}
#@ ntasks: 2
#@ time: 10
#@ tags: app bio

featureCounts -T 2 -F SAF -a genes.saf -o counts.txt reads.sam > fc.log 2>&1 || { tail fc.log >&2; exit 1; }
echo "unstranded:"
awk 'NR > 2 { print $1, $6, $7 }' counts.txt
grep -E '^(Assigned|Unassigned_NoFeatures)' counts.txt.summary
featureCounts -T 2 -F SAF -s 1 -a genes.saf -o stranded.txt reads.sam > fc2.log 2>&1 || { tail fc2.log >&2; exit 1; }
echo "stranded (-s 1):"
awk 'NR > 2 { print $1, $7 }' stranded.txt
