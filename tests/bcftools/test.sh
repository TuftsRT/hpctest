#!/bin/bash
#@ description: bcftools sort, compress, index, filter, region query and stats
#@ param bcftools = bcftools
#@ modules: ${bcftools}
#@ ntasks: 1
#@ time: 5
#@ tags: app bio

bcftools sort -Oz -o calls.vcf.gz calls.vcf 2>/dev/null
bcftools index calls.vcf.gz
echo "chr1 records:"
bcftools query -r chr1 -f '%CHROM\t%POS\t%REF\t%ALT\n' calls.vcf.gz
echo "QUAL>=40 SNPs:"
bcftools view -H -i 'QUAL>=40' -v snps calls.vcf.gz | cut -f1,2
echo "S2 genotypes: $(bcftools query -s S2 -f '[%GT]\n' calls.vcf.gz | tr '\n' ' ')"
bcftools stats calls.vcf.gz | grep -E '^SN' | cut -f3- | grep -E 'number of (records|SNPs|indels):'
