### Snakemake plan for the whole workflow

# Define input path for fastq files
import glob
import os
import re

## Set input paths, then extract sample names via regexpr
input_path_fq = "../data/X201SC19060242-Z01-F001/raw_data/"
input_base_fq = [re.search("[A-Z,0-9,_]*(?=.fq)", f) for f in glob.glob(input_path_fq + "*.fq.gz")]
input_base_fq = [f.group() for f in input_base_fq]

# Download reference mycoplasma genome
rule download_mycoplasma:
  output:  '../data/mycoplasma/GCF_003663725.1_ASM366372v1_rna_from_genomic.fna.gz'
  shell: 'wget -r -np -k -N -nd -P ../data/mycoplasma/ ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/663/725/GCF_003663725.1_ASM366372v1/'


# Test sequences with fastqc
rule fastqc:
  input:
    expand("{path}{base}.fq.gz", path = input_path_fq, base = input_base_fq)
  output:
    expand('./results/fastqc/{base}_fastqc.html', base = input_base_fq),
    expand('./results/fastqc/{base}_fastqc.zip', base = input_base_fq)
  shell: 'nice --adjustment=+10 fastqc {input} -o=./results/fastqc/ -t=128'


# Trim 20 bp from 5' end to remove primer adapter bias

# Map to reference mycoplasma genome

# Quantify mycoplasma expression
