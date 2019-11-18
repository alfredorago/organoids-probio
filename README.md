# organoids-probio
Comparisons of gut organoid transcriptomic responses to different probiotic strains

## Global considerations

The workplace needs to be setup within a conda environment for snakemake. 
This can be created by running 
```bash
conda env create -f envs/pymake.yaml
```
or 

```bash
conda create -n pymake -c bioconda -c conda-forge snakemake=5.7.0
```

Refer to the Snakefile file for the list of script to run and the dependencies

All scripts run from R version 3.5.0, as installed on Nyx (not Hestia).
We use packrat to keep track of all package versions.

We need to manually set the path to Pandoc to compile Rmd scripts from the workflow.
This is currently implemented via the .zshrc script.

## Directed Acyclic Graph of the global workflow 

![Workflow Graph](dag.png)

Created using the command 
```bash
snakemake --dag | dot -Tpng > dag.png
```

## Testing plan
2 hours post-exposure, aka same time window as biopsy paper

0) PCA/clustering on all samples without LGG

1) 3D Homemade (27 samples, one clonal line per sample) vs 3D Intesticult (multiple cultures from the same clonal line)

2) 2D Intesticult (3 samples per clonal line) vs 3D Intesticult
between vs within genome variance in intesticult lines

3) 2D intesticult vs 2D intesticult + LGG
3 samples per clonal line in each
We can use this as a reproducibility check once we get the final data on bacterial exposure

3b) 2d organoids w&wo LGG + biopsy samples (PCA & Hclust)
patient/treatment/sample type/cell line

PCA comparing the LGG response vector of biopsy samples to the LGG response vector of 2D organoid samples
