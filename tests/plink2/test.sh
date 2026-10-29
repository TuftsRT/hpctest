#!/bin/bash
#@ description: PLINK 2 VCF import, allele frequencies, genotype counts, missingness, MAF filter (6 samples)
#@ param plink2 = plink2
#@ modules: ${plink2}
#@ ntasks: 2
#@ mem: 2G
#@ time: 5
#@ tags: app bio

plink2() { command plink2 --threads 2 --memory 1000 "$@" >> plink2.log 2>&1 || { tail plink2.log >&2; exit 1; }; }
plink2 --vcf genotypes.vcf --make-pgen --out geno
plink2 --pfile geno --freq --geno-counts --missing --out stats
cut -f2,5,6 stats.afreq
cut -f2,5-7,10 stats.gcount
awk '$2 > 0' stats.smiss
plink2 --pfile geno --maf 0.2 --write-snplist --out common
echo "MAF >= 0.2: $(tr '\n' ' ' < common.snplist)"
