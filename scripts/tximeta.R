### Import data from salmon raw output into R
# Note: this script uses tximport as installed from the github repository, since the bioconductor version for R3.5 has bugs

# Set library to local folder
.libPaths(
  c(
    './packrat/lib/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-ext/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-R/x86_64-pc-linux-gnu/3.6.1')
)

# Load packagess
library(magrittr)
library(tximeta)
library(tidyverse)

# List salmon files and sample names
column_data <-
  tibble(
    files = unlist(snakemake@input)
  ) %>%
  mutate(
    .,
    names = str_extract(string = files, pattern = "[:upper:]_[:digit:]+")
  )

# Retrieve feature metadata
# NOTE: We lose all features that lack metadata at this step
setTximetaBFC(dir = "data/tximetaBFC")

transcript_data <- tximeta(
  coldata = column_data,
  type = "salmon",
  txOut = TRUE
)

# Convert to gene level
gene_data <- summarizeToGene(
  object = transcript_data,
  varReduce = TRUE,
  ignoreTxVersion = TRUE,
  ignoreAfterBar = TRUE,
  countsFromAbundance = 'lengthScaledTPM'
)

# Save output
saveRDS(object = gene_data, file = snakemake@output[[1]])
