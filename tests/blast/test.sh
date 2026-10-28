#!/bin/bash
#@ description: BLAST+ blastn search of E. coli genes against a site database
#@ param blast = blast-plus
#@ param blast_db =
#@ param blast_db_name = tsa_nt
#@ requires-param: blast_db
#@ modules: ${blast}
#@ ntasks: 1
#@ cpus-per-task: 8
#@ time: 15
#@ tags: app bio

# blast_db: directory holding the BLAST database (set in site.conf [params]).
threads=${SLURM_CPUS_PER_TASK:-8}
blastn -db "$blast_db/$blast_db_name" -num_threads $threads -query Ecoli.dna.loc.fasta \
    -out hits.tsv -outfmt 6 -evalue 1e-10 2>&1 | grep -v '^INFO:'
echo "hits: $(head hits.tsv | wc -l)"
