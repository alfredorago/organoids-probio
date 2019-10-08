#!/bin/bash

# run this by using the shell command
# scripts/trim_reads.sh &> results/trim_reads/log.txt &
# disown
# this launches it in the background and redirects the stdout and stderr logs
# the disown command makes sure the process keeps running after logout

echo "Initializing hard trimming of first 20 bp"

fastq_dir_in=./data/X201SC19060242-Z01-F001/raw_data/

fastq_dir_out=./results/trim_reads/

fastq_files=$(ls ${fastq_dir_in}* | grep -oh "A_[0-9,_]*")

echo $fastq_files

for file in $fastq_files
do

echo $file
nice --adjustment=+10 seqtk trimfq -b 20 ${fastq_dir_in}${file}.fq.gz > ${fastq_dir_out}${file}_trimmed.fq

done

echo "Trimming finished"
