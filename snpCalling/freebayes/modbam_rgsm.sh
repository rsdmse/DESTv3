#! /bin/bash
#SBATCH -p workq
#SBATCH --mem=8G
#SBATCH --export=ALL

module load bioinfo/samtools/1.20

file=$1
base_name=$(echo $file |awk '{split($1,tmp,"\.");{print tmp[1]}}' -)
samtools addreplacerg -w -r "@RG\\tID:${base_name}\\tPL:ILLUMINA\\tLB:Lib-${base_name}\\tSM:${base_name}" -o ${base_name}.smrgmod.bam $file
samtools index ${base_name}.smrgmod.bam


