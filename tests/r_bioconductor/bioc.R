# Bioconductor known-answer checks: Biostrings, GenomicRanges, edgeR, DESeq2.
suppressPackageStartupMessages({
  library(Biostrings); library(GenomicRanges); library(edgeR); library(DESeq2)
})

# Biostrings
dna <- DNAString("ATGGCCATTGTAATGGGCCGCTGA")
cat("revcomp:", as.character(reverseComplement(dna)), "\n")
cat("protein:", as.character(translate(dna)), "\n")
cat("GC fraction:", round(letterFrequency(dna, "GC", as.prob = TRUE)[1], 4), "\n")
pd <- matchPattern("GCC", dna)
cat("GCC at:", start(pd), "\n")

# GenomicRanges
genes <- GRanges("chr1", IRanges(c(100, 500, 900), width = 200), strand = "+",
                 name = c("gA", "gB", "gC"))
reads <- GRanges("chr1", IRanges(c(150, 180, 550, 650, 1500), width = 50))
cat("reads per gene:", countOverlaps(genes, reads), "\n")
red <- reduce(GRanges("chr1", IRanges(c(1, 50, 300), c(100, 120, 400))))
cat("reduced:", paste0(start(red), "-", end(red)), "\n")

# Count matrix: 50 genes x 6 samples (3 A, 3 B), negative binomial with a fixed seed;
# genes 1-3 are 8x up in B, genes 4-5 are 8x down.
set.seed(42)
mu <- matrix(200 + 20 * (1:50), 50, 6)
mu[1:3, 4:6] <- mu[1:3, 4:6] * 8
mu[4:5, 4:6] <- mu[4:5, 4:6] / 8
counts <- matrix(rnbinom(300, mu = mu, size = 50), 50, 6)
rownames(counts) <- sprintf("gene%02d", 1:50)
group <- factor(rep(c("A", "B"), each = 3))

# edgeR exact test
y <- DGEList(counts, group = group)
y <- normLibSizes(y)
y <- suppressMessages(estimateDisp(y))
et <- topTags(exactTest(y), n = Inf)$table
cat("edgeR FDR<0.01:", sort(rownames(et)[et$FDR < 0.01]), "\n")

# DESeq2 Wald test
dds <- suppressMessages(DESeqDataSetFromMatrix(counts, data.frame(group = group), ~ group))
dds <- suppressMessages(DESeq(dds, quiet = TRUE))
res <- results(dds)
sig <- rownames(res)[!is.na(res$padj) & res$padj < 0.01]
cat("DESeq2 padj<0.01:", sort(sig), "\n")
cat("DESeq2 log2FC (genes 1-5) rounded:", sprintf("%.0f", res$log2FoldChange[1:5]), "\n")
