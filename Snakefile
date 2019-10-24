### Snakemake plan for the whole workflow

# Define input path for fastq files
input_path_fq = "data/X201SC19060242-Z01-F001/raw_data/"
input_base_fq, = glob_wildcards("data/X201SC19060242-Z01-F001/raw_data/{base}.fq.gz")
# Define standard bowtie2 reference suffixes
bowtie_suffixes = (
  *[".{id}.bt2".format(id = i) for i in range(1,5)],
  *[".rev.{id}.bt2".format(id = i) for i in range(1,3)]
)

# rule all to generate all output files at once
rule all:
  input:
    mycoplasma_transcriptome = 'data/mycoplasma/GCF_003663725.1_ASM366372v1_rna_from_genomic.fna.gz',
    fastqc_reports = expand("results/fastqc/{base}_fastqc.html", base = input_base_fq),
    trimmed_fastq = expand("results/trim_reads/{base}.fq", base = input_base_fq),
    human_reference_bowtie2 = expand("data/fastq_screen_references/FastQ_Screen_Genomes/Human/Homo_sapiens.GRCh38{suffix}", suffix = bowtie_suffixes),
    mycoplasma_reference = expand("results/mycoplasma_reference/mycoplasma_reference{suffix}", suffix = bowtie_suffixes),
    fastq_txt = expand("results/fastq_report/{basename}.txt", basename = input_base_fq),

# Download reference mycoplasma genome
rule download_mycoplasma:
  output:
    'data/mycoplasma/GCF_003663725.1_ASM366372v1_rna_from_genomic.fna.gz'
  log:
    "logs/download_mycoplasma.txt"
  shell:
    'wget -r -np -k -N -nd -P data/mycoplasma/ ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/663/725/GCF_003663725.1_ASM366372v1/ 2> {log}'

# Test sequences with fastqc
rule fastqc:
  input:
    fq = expand("{path}{base}.fq.gz", base = input_base_fq, path = input_path_fq)
  output:
    expand("results/fastqc/{base}_fastqc.html", base = input_base_fq)
  log:
    "logs/fastqc"
  shell:
    "nice --adjustment=+10 fastqc {input.fq} -o={fq_outpath} -t=128 2> {log}"

# Trim 20 bp from 5' end to remove primer adapter bias
rule trim_reads:
  params:
    in_base = input_base_fq,
    in_path = input_path_fq
  input:
    expand("{path}{base}.fq.gz", base = input_base_fq, path = input_path_fq)
  output:
    expand("results/trim_reads/{base}.fq", base = input_base_fq)
  shell:
    '''
    for file in {params.in_base}
    do
    nice --adjustment=+10 seqtk trimfq -b 20 {params.in_path}$file.fq.gz > results/trim_reads/$file.fq
    done
    '''

# Download reference genomes for human and mouse
rule reference_index:
  output:
    expand("data/fastq_screen_references/FastQ_Screen_Genomes/Human/Homo_sapiens.GRCh38{suffix}", suffix = bowtie_suffixes)
  shell:
    "fastq_screen --get_genomes --outdir data/fastq_screen_references"

# Map to mycoplasma transcriptome
rule mycoplasma_reference:
  input:
    'data/mycoplasma/GCF_003663725.1_ASM366372v1_genomic.fna.gz'
  output:
    mycoplasma_genome = temp("results/mycoplasma_reference/mycoplasma_genome.fa"),
    mycoplasma_reference = expand("results/mycoplasma_reference/mycoplasma_reference{suffix}", suffix = bowtie_suffixes),
  shell:
    '''
    gzip -cd {input} > {output.mycoplasma_genome}  &&
    bowtie2-build --seed 42 {output.mycoplasma_genome} mycoplasma_reference &&
    mv mycoplasma_reference* results/mycoplasma_reference
    '''

# Use fastq Screen for mycoplasma detection

# Quantify mycoplasma expression
