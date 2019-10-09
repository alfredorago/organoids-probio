### Snakemake plan for the whole workflow

# Download reference mycoplasma genome
rule download_mycoplasma:
  output:
    directory('../data/mycoplasma')
  shell: 'wget -r -np -k -N -nd -P ../data/mycoplasma/ ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/003/663/725/GCF_003663725.1_ASM366372v1/'
