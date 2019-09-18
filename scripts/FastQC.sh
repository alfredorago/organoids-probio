#!/bin/bash

echo "Initializing fastqc analysis"
fastq_files="ls ./data/X201SC19060242-Z01-F001/raw_data/*.fq.gz"
#echo ${fastq_files}
for file in $fastq_files
do
  echo ${file}
  nice --adjustment=+10 fastqc ${file} -o=./results/fastqc/
done

echo "Fastqc finished"
