#!/bin/bash
# run this by using the shell command
# scripts/FastQC.sh > results/fastqc/log.txt 2>&1 &
# disown
# this launches it in the background and redirects the stdout and stderr logs
# the disown command makes sure the process keeps running after logout

echo "Initializing fastqc analysis"
fastq_files="ls ./data/X201SC19060242-Z01-F001/raw_data/*.fq.gz"
#echo ${fastq_files}
nice --adjustment=+10 fastqc ${fastq_files} -o=./results/fastqc/ -t=128

echo "Fastqc finished"
