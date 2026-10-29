# splits.awk: print the non-trivial bipartitions (splits) of a Newick tree, one per line:
# the side without the alphabetically first taxon, members sorted, lines sorted.
# Compares topology only: branch lengths, support values, rooting and child order are ignored.
function sort_list(arr, n,   a, b, tmp) {
    for (a = 1; a <= n; a++) for (b = a + 1; b <= n; b++)
        if (arr[b] < arr[a]) { tmp = arr[a]; arr[a] = arr[b]; arr[b] = tmp }
}
{ t = t $0 }
END {
    d = 0; name = ""; skip = 0; ns = 0
    for (i = 1; i <= length(t); i++) {
        ch = substr(t, i, 1)
        if (ch == "(") { d++; grp[d] = ""; skip = 0; continue }
        if (ch == "," || ch == ")" || ch == ";") {
            if (name != "") { grp[d] = grp[d] " " name; taxa[name] = 1; name = "" }
            skip = 0
            # after ")" comes an optional support label and branch length: skip them
            if (ch == ")") { s = grp[d]; d--; grp[d] = grp[d] s; clade[++ns] = s; skip = 1 }
            continue
        }
        if (ch == ":") { skip = 1; continue }
        if (!skip && ch !~ /[ \t\047]/) name = name ch
    }
    nt = 0; for (x in taxa) all[++nt] = x
    sort_list(all, nt); first = all[1]
    for (k = 1; k <= ns; k++) {
        split("", in_); m = split(clade[k], mem, " ")
        for (j = 1; j <= m; j++) in_[mem[j]] = 1
        if (m < 2 || m > nt - 2) continue
        flip = (first in in_); cnt = 0
        for (j = 1; j <= nt; j++) if ((all[j] in in_) != flip) side[++cnt] = all[j]
        out = side[1]; for (a = 2; a <= cnt; a++) out = out "," side[a]
        if (!(out in seen)) { seen[out] = 1; lines[++nl] = out }
    }
    sort_list(lines, nl)
    for (k = 1; k <= nl; k++) print lines[k]
}
