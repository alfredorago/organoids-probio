# organoids-probio
Comparinsons of gut organoid transcriptomic responses to different probiotic strains

## Global considerations

I am implementing the project as a Drake workflow. 
The main runall script is the _drake.R file in the main working directory.
The plan (in scripts) stores all objects for drake versioning.
The files libraries and function store the stuff that needs to be loaded in order for the drake workflow to run.

## Quality control

We store the results from fastqc, and summarize them using the fastqcr package.
Note that fastqc analyses are *not* included in the drake workflow, only the summaries are.
Before running those, use the fastqc.sh script to generate the fastqc reports
