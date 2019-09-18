## Generate Fastqc reports for all samples

library(fastqcr)
library(here)

qc.in  <- file.path("../../data/X201SC19060242-Z01-F001/raw_data/")
qc.out <- here("results/fastqc")

fastqc(fq.dir = qc.in, qc.dir = qc.out, threads = 64, fastqc.path = "/usr/local/bin/fastqc")
