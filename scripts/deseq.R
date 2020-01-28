## Perform differential expression analysis via DESeq2

# Set library to local folder
.libPaths(
  c(
    './packrat/lib/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-ext/x86_64-pc-linux-gnu/3.6.1',
    './packrat/lib-R/x86_64-pc-linux-gnu/3.6.1')
)

library("DESeq2")
library("BiocParallel")
library("magrittr")

register(MulticoreParam(snakemake@threads))

# Import dataset (note, we keep samples from both labs even though there is only one cell line from probio)
experiment_data <-  readRDS(file = snakemake@input[[1]])

# Contrast 3D vs control 2D organoids
DE_2D_vs_3D <-
  experiment_data %>%
  subset(., select = treatment != "LGG")

DE_2D_vs_3D$treatment <-
  droplevels(DE_2D_vs_3D$treatment) %>%
  relevel(., ref = "3D")

DE_2D_vs_3D<-
  DE_2D_vs_3D %>%
  DESeqDataSet(se = ., design = ~ patient_id + treatment) %>%
  DESeq(., parallel = T)

saveRDS(object = DE_2D_vs_3D, file = snakemake@output[["controls"]])

# Contrast 2D control vs 2D treatment organoids
DE_2D_vs_LGG <-
  experiment_data %>%
  subset(., select = treatment != "3D")

DE_2D_vs_LGG$treatment <- droplevels(DE_2D_vs_LGG$treatment)

DE_2D_vs_LGG <-
  DE_2D_vs_LGG %>%
  DESeqDataSet(se = ., design = ~ patient_id + treatment) %>%
  DESeq(., parallel = T)

saveRDS(object = DE_2D_vs_LGG, file = snakemake@output[["probiotics"]])
