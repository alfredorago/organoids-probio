## Drake plan: decides what to run for the analysis.
## Note: it requires we call fastqc before the main analysis
plan = drake_plan(
  # Find fastq and fastqc files
  fastq_dir = here("data/X201SC19060242-Z01-F001/raw_data/"),
  fastqc_dir = here("results/fastqc/"),

  fastqc_tibble = qc_aggregate(qc.dir = fastqc_dir, progressbar = F),
  fastqc_report = qc_report(qc.path = fastqc_dir,
                            result.file = file_out(here("results/fastqcr/mycoplasma_report")),
                            experiment = "LGG 2D organoids, mycoplasma infected",
                            interpret = T)


)
