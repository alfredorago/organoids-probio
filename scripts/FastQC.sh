#!/bin/bash

echo "Initializing fastqc analysis"
fastq_files="ls ./data/X201SC19060242-Z01-F001/raw_data/*.fq.gz"
#echo ${fastq_files}
nice --adjustment=+10 fastqc ${fastq_files} -o=./results/fastqc/ -t=128

echo "Fastqc finished"
