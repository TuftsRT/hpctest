# compare_contigs.awk REF.fa CONTIGS.fa: number of contigs, and whether the longest
# contig is an exact substring of the reference (either strand) covering >= 98% of it.
function rc(s,   i, r) { r = ""; for (i = length(s); i > 0; i--) r = r comp[substr(s, i, 1)]; return r }
BEGIN { comp["A"] = "T"; comp["C"] = "G"; comp["G"] = "C"; comp["T"] = "A" }
FNR == 1 { f++ }
/^>/ { if (f == 2) n++; next }
f == 1 { ref = ref $0; next }
{ c[n] = c[n] $0 }
END { best = ""
      for (i = 1; i <= n; i++) if (length(c[i]) > length(best)) best = c[i]
      printf "reference length: %d, contigs: %d\n", length(ref), n
      print "longest contig matches the reference exactly:", (index(ref, best) || index(ref, rc(best))) ? "yes" : "no"
      print "longest contig covers >= 98% of the reference:", length(best) >= 0.98 * length(ref) ? "yes" : "no" }
