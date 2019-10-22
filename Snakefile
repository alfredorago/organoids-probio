### Snakemake plan for the whole workflow

# Define input path for fastq files
input_path_fq = "../data/X201SC19060242-Z01-F001/raw_data/"
input_base_fq, = glob_wildcards("../data/X201SC19060242-Z01-F001/raw_data/{base}.fq.gz")

# rule all to generate all output files at once
rule all:
  input:
    mycoplasma_transcriptome = 'data/mycoplasma/GCF_003663725.1_ASM366372v1_rna_from_genomic.fna.gz',
    fastqc_reports = expand("results/fastqc/{base}_fastqc.html", base = input_base_fq),
    trimmed_fastq = expand("results/trim_reads/{base}.fq", base = input_base_fq)

# Download reference mycoplasma genome
rule download_mycoplasma:
  output:
    'data/mycoplasma/GCF_003663725.1_ASM366372v1_rna_from_genomic.fna.gz'
  log:
    "logs/download_mycoplasma.txt"
  shell:
    'wget -r -np -k -N -nd -P ../data/mycoplasma/ ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/663/725/GCF_003663725.1_ASM366372v1/ 2> {log}'

# Test sequences with fastqc
rule fastqc:
  input:
    fq = expand("{path}{base}.fq.gz", base = input_base_fq, path = input_path_fq)
  output:
    expand("results/fastqc/{base}_fastqc.html", base = input_base_fq)
  log: "logs/fastqc"
  shell:
    "nice --adjustment=+10 fastqc {input.fq} -o={fq_outpath} -t=128 2> {log}"

# Trim 20 bp from 5' end to remove primer adapter bias
rule trim_reads:
  input:
    fq = expand("{path}{base}.fq.gz", base = input_base_fq, path = input_path_fq)
  output:
    expand("results/trim_reads/{base}.fq", base = input_base_fq)
  log:
    "logs/trim_reads.txt"
  shell:
    "nice --adjustment=+10 seqtk trimfq -b 20 {input.fq} > {output} 2> {log}"

# Index Mycoplasma transcriptome

# Map to reference mycoplasma genome

# Quantify mycoplasma expression
