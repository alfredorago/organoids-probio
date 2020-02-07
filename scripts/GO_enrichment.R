## Perform random-forest based GO enrichment analyses

# Set library to local folder
.libPaths(
  c(
    './packrat/lib/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-ext/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-R/x86_64-pc-linux-gnu/3.6.1')
)

library(magrittr)
library(stringr)
library(dplyr)

library(DESeq2)
library(biomaRt)
library(GOexpress)
library(GO.db)
library(fdrtool)

register(MulticoreParam(snakemake@threads))
set.seed(42)

## Import read counts and metadata
culture_type_dataset <- readRDS(file = snakemake@input[[1]])
culture_type_results <- results(culture_type_dataset)
metadata <- colData(culture_type_dataset)

## Filter only expressed genes and apply vst
culture_type_counts_filtered <-
  culture_type_results %$%
  is.na(padj) %>%
  not() %>%
  which() %>%
  culture_type_dataset[.,] %>%
  vst()

## Row-normalize so genes have the same expression range
culture_type_counts_scaled <-
  culture_type_counts_filtered %>%
  assay() %>%
  apply(X = ., MARGIN = 1, FUN = scale, center = TRUE, scale = TRUE) %>%
  t() %>%
  set_rownames(., assay(culture_type_counts_filtered) %>% row.names %>% str_extract(string = ., pattern = "^[[:alnum:]]*")) %>%
  set_colnames(., assay(culture_type_counts_filtered) %>% colnames)

## Convert to expression set so we can input it to GOexpress
culture_type_phenodata =
  new("AnnotatedDataFrame",
      data = as.data.frame(metadata),
      varMetadata = colnames(metadata) %>% data.frame(labelDescription = ., row.names = .)
  )

expression_set <-
  ExpressionSet(
    assayData = culture_type_counts_scaled,
    phenoData = culture_type_phenodata
  )

## Download GO reference tables
GO_table = getBM(
  attributes = c("ensembl_gene_id", "go_id"),
  mart = useEnsembl(biomart = 'ensembl', dataset = 'hsapiens_gene_ensembl')
) %>%
  set_colnames(c("gene_id", "go_id"))

GO_ontologies = select(
  GO.db,
  keytype = "GOID",
  keys = unique(GO_table$go_id),
  column = c("GOID", "DEFINITION", "ONTOLOGY")
) %>%
  set_colnames(c("go_id", "name", "namespace")) %>%
  mutate(
    namespace = factor(x = namespace, levels = c("CC", "BP", "MF"), labels = c("cellular_component", "biological_process", "molecular_function"))
  )

saveRDS(object = expression_set, file = snakemake@output[["expression_set"]])

## Run random forest algorithm
GO_results <- GO_analyse(
  eSet = expression_set,
  f = "treatment",
  GO_genes = GO_table,
  all_GO = GO_ontologies,
  method = "rf",
  ntree = snakemake@params[["ntree"]]
)

## Filter low-count GOs, calculate p-values and save as RDS file for visualization
GO_pvalues =
  GO_results %>%
  subset_scores(total = snakemake@params[["min_genes_per_GO"]]) %>%
  pValue_GO(N = snakemake@params[["p_value_permutations"]] )

saveRDS(object = GO_pvalues, file = snakemake@output[["GO_results"]])

## Correct via fdr and save table of results
GO_qvalues =
  GO_pvalues %$%
  GO %>%
  mutate(
    q.val = fdrtool(p.val)$qval
  )

write.csv(x = GO_qvalues, file = snakemake@output[["q_value_table"]])
