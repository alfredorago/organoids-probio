## Drake plan: decides what to run for the analysis.
## Note: it requires we call fastqc before the main analysis
plan = (
  # Find fastq and fastqc files
  fastq_dir = here("data/X201SC19060242-Z01-F001/raw_data/"),
  fastqc_dir = here("results/fastqc/")

)
