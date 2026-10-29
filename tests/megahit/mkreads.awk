# Simulate 100 bp reads from the genome: start every 1-5 bp (uneven coverage, ~33x),
# alternating strands, one substitution error in every 7th read away from the genome ends (FASTQ).
function rc(s,   i, r) { r = ""; for (i = length(s); i > 0; i--) r = r comp[substr(s, i, 1)]; return r }
BEGIN { comp["A"] = "T"; comp["C"] = "G"; comp["G"] = "C"; comp["T"] = "A"
        q = sprintf("%100s", ""); gsub(/ /, "I", q) }
!/^>/ { g = g $0 }
END { n = 0
      for (p = 1; p + 99 <= length(g); p += 1 + (n * 7) % 5) {
          s = substr(g, p, 100)
          if (n % 7 == 0 && p > 100 && p < length(g) - 200) { e = 1 + (n * 13) % 100; b = substr(s, e, 1)
                            s = substr(s, 1, e - 1) comp[b] substr(s, e + 1) }
          if (n % 2) s = rc(s)
          printf "@r%d\n%s\n+\n%s\n", n++, s, q } }
