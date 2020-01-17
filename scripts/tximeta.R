### Import data from salmon raw output into R
# Note: this script uses tximport as installed from the github repository:
# the bioconductor version for R3.5 has bugs

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
library(SummarizedExperiment)
library(DESeq2)

# List salmon files and sample names, plus metadata
column_data <-
  read_csv(file = snakemake@input[["sample_metadata"]],
           col_names = TRUE,
           col_types = cols(
             tube_id = "c",
             patient_id = "c",
             treatment = col_factor(levels = c("Control", "LGG", "3D"), ordered = FALSE),
             replicate = "c",
             batch = "c",
             sex = col_factor(levels = c("f","m"), ordered = FALSE),
             room = "c"
           )) %>%
  mutate(
    .,
    files = snakemake@input[["salmon_files"]],
    names = str_extract(string = files, pattern = "[:upper:]_[:digit:]+")
  )

# Retrieve feature metadata (transcript names)
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

# Convert to DESeq object
#
# gene_data_de <- DESeqDataSet(se = gene_data, design = ~ treatment)
# vsd <- vst(gene_data_de)
