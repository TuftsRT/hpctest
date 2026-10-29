#!/bin/bash
#@ description: VCFtools allele frequencies, indel/FILTER removal, missingness and HWE counts on a 6-sample VCF
#@ param vcftools = vcftools
#@ modules: ${vcftools}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

vcftools() { command vcftools "$@" >> vcftools.log 2>&1 || { tail vcftools.log >&2; exit 1; }; }
vcftools --vcf genotypes.vcf --freq2 --out freq
cat freq.frq
vcftools --vcf genotypes.vcf --remove-indels --remove-filtered-all --recode --out snps
grep 'kept .* Sites' vcftools.log | tail -1
echo "kept: $(grep -v '^#' snps.recode.vcf | cut -f3 | tr '\n' ' ')"
vcftools --vcf genotypes.vcf --missing-indv --out miss
awk '$4 > 0' miss.imiss
vcftools --vcf genotypes.vcf --hardy --out hwe
cut -f1-3 hwe.hwe
