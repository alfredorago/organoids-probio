### Import data from salmon raw output into R
# Note: this script uses tximport as installed from the github repository, since the bioconductor version for R3.5 has bugs


# Load packagess
library(here)
library(magrittr)
library(tximport, lib.loc = 'packrat/lib/x86_64-pc-linux-gnu/3.5.0')
library(biomaRt)

# Download Transcript to Gene conversion table
transcript_to_gene_id = getBM(
  attributes = list('ensembl_transcript_id', "ensembl_gene_id"),
  mart = useEnsembl(biomart = 'ensembl', dataset = 'hsapiens_gene_ensembl')
)

# Convert Salmon output to expression table
expression_data <-
  unlist(snakemake@input) %>%
  paste(., 'quant.sf', sep = '/') %>%
  tximport(
    files = ., type = "salmon",
    txIn = T, txOut = F,
    countsFromAbundance = 'lengthScaledTPM', varReduce = T,
    tx2gene = transcript_to_gene_id, ignoreTxVersion = T)

# Save output
saveRDS(object = expression_data, file = snakemake@output[[1]])
