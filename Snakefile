### Snakemake plan for the whole workflow

# Define input path for fastq files
input_path_fq = "data/X201SC19060242-Z01-F001/raw_data/"
input_base_fq, = glob_wildcards("data/X201SC19060242-Z01-F001/raw_data/{base}.fq.gz")
sample_id = glob_wildcards("data/X201SC19060242-Z01-F001/raw_data/{base}_1.fq.gz")

# Define standard bowtie2 reference suffixes
bowtie_suffixes = (
  *[".{id}.bt2".format(id = i) for i in range(1,5)],
  *[".rev.{id}.bt2".format(id = i) for i in range(1,3)]
)

# rule all to generate all output files at once
rule all:
  params:
    in_base = input_base_fq,
    in_path = input_path_fq
  input:
    fastq_files = expand("{path}{base}.fq.gz", base = input_base_fq, path = input_path_fq),
    fastqc_reports = expand("results/fastqc/{base}_fastqc.html", base = input_base_fq),
    mycoplasma_report = "results/reports/mycoplasma_report.html",
    quant = [expand("results/salmon/salmon_quant/{id}", id = id) for id in sample_id],
    tximport = 'results/tximport/expression_data.Rdata'

# Download reference mycoplasma genome
rule download_mycoplasma:
  output:
    'data/mycoplasma/GCF_003663725.1_ASM366372v1_genomic.fna.gz'
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
  threads: 6
  shell:
    "nice --adjustment=+10 fastqc {input.fq} -threads {threads} -o=results/fastqc/ 2> {log}"

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
rule fastq_screen:
  input:
    shared_reference_genomes = expand("data/fastq_screen_references/FastQ_Screen_Genomes/Human/Homo_sapiens.GRCh38{suffix}", suffix = bowtie_suffixes),
    fastq = expand("results/trim_reads/{basename}.fq", basename = input_base_fq),
    mycoplasma_reference = expand("results/mycoplasma_reference/mycoplasma_reference{suffix}", suffix = bowtie_suffixes),
  output:
    fastq_txt = expand("results/fastq_screen/{basename}_screen.txt", basename = input_base_fq),
    fastq_html = expand("results/fastq_screen/{basename}_screen.html", basename = input_base_fq),
  threads: 16
  shell:
    '''
    nice --adjustment=+10 \
    fastq_screen \
        --subset 0 --outdir results/fastq_screen --conf scripts/fastq_screen.conf --threads {threads} {input.fastq}
    '''

# Create report on mycoplasma contmination
rule mycoplasma_report:
  input:
    fastq_txt = expand("results/fastq_screen/{basename}_screen.txt", basename = input_base_fq),
    script = "scripts/mycoplasma_report.Rmd"
  output:
    "results/reports/mycoplasma_report.html"
  shell:
    '''
    Rscript -e "rmarkdown::render('{input.script}')"
    mv scripts/mycoplasma_report.html results/reports/mycoplasma_report.html
    '''

# Download human reference transcriptome from ENSEMBL
rule download_human:
  output:
    transcriptome = 'data/Human/Homo_sapiens.GRCh38.cdna.all.fa.gz',
    genome = 'data/Human/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz2'
  log:
    "logs/download_human.txt"
  shell:
    '''
    wget -r -np -k -N -nd -P data/Human/ ftp://ftp.ensembl.org/pub/release-98/fasta/homo_sapiens/cdna/ 2> {log}
    curl -o {output.genome} ftp://ftp.ensembl.org/pub/release-98/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
    '''

# Index human genome for salmon quantification
rule salmon_index:
  input:
      transcripts = "data/Human/Homo_sapiens.GRCh38.cdna.all.fa.gz",
      genome = "data/Human/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz2"

  output:
      decoys = temp("results/salmon/human_transcriptome_index/decoys.txt"),
      gentrome = temp("results/salmon/human_transcriptome_index/gentrome.fa"),
      index = directory("results/salmon/human_transcriptome_index/ref_idexing"),

  threads: 16

  params:
      kmer = 31

  shell:
      '''
      # Crate decoy file
      echo "Creating Decoy File"
      grep "^>" <(zcat {input.genome}) | cut -d " " -f 1 > {output.decoys} &&
      sed -i -e 's/>//g' {output.decoys} &&

      # Concatenate genome and transcriptome
      echo "Concatenating genome and transcriptome"
      zcat {input.transcripts} {input.genome} > {output.gentrome} &&

      # Create index
      echo "Creating index"
      salmon index \
                -t {output.gentrome} \
                -i {output.index} \
                -d {output.decoys} \
                -p {threads} \
                -k {params.kmer}
      '''

# Quantify read counts via Samon
rule salmon_quant:
  input:
    index = "results/salmon/human_transcriptome_index/ref_idexing",
    reads_1 = [expand("results/trim_reads/{id}_1.fq", id = id) for id in sample_id],
    reads_2 = [expand("results/trim_reads/{id}_2.fq", id = id) for id in sample_id]

  output:
    quant = directory([expand("results/salmon/salmon_quant/{id}", id = id) for id in sample_id])

  params:
    libtype = "ISR",
    numBootstraps = 30,
    minScoreFraction = 0.8,
    jobs = 6,
    salmonThreads = 5

  threads: 30

  shell:
    '''

    parallel --link --jobs {params.jobs} --nice 20 \
    salmon quant \
            -i {input.index} \
            -l {params.libtype} \
            -1 {{1}} \
            -2 {{2}} \
            -o {{3}} \
            --validateMappings \
            --minScoreFraction {params.minScoreFraction} \
            --numBootstraps {params.numBootstraps}\
            --gcBias \
            --seqBias \
            --writeUnmappedNames \
            --threads {params.salmonThreads} \
    ::: {input.reads_1} \
    ::: {input.reads_2} \
    ::: {output.quant}

    '''

# Import reads into R via tximport
rule tximport:
  input:
    [expand("results/salmon/salmon_quant/{id}", id = id) for id in sample_id]
  output:
   'results/tximport/expression_data.Rdata'
  script:
    'scripts/tximport.R'
