#!/bin/bash
# run this by using the shell command
# scripts/trim_galore.sh &
# disown
# this launches it in the background and redirects the stdout and stderr logs
# the disown command makes sure the process keeps running after logout

echo "Initializing hard trimming of first 20 bp"
fastq_files_E1=$(ls ./data/X201SC19060242-Z01-F001/raw_data/*1.fq.gz)
fastq_files_E2=$(ls ./data/X201SC19060242-Z01-F001/raw_data/*2.fq.gz)

echo Trimming $(wc $fastq_files_E1 -w) R1 Sequences and $(wc $fastq_files_E2 -w) R2 sequences

nice --adjustment=+10 ../TrimGalore-0.6.0/trim_galore --paired --hardtrim3 20 -o ./results/trim_galore/ $fastq_files_E1 $fastq_files_E2

echo "Trimming finished"
