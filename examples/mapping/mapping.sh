#!/usr/bin/env bash
#
#SBATCH -J dockerMap # A single job name for the array
#SBATCH -c 20 ### 20 cores
#SBATCH -N 1 # on one node
#SBATCH -t 72:00:00
#SBATCH --mem 90G
#SBATCH -o /scratch/aob2x/logs/RunDest.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/logs/RunDest.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab


### run as: sbatch /home/aob2x/DESTv3/examples/mapping/mapping.sh
### sacct -j 5479919
### cat /scratch/aob2x/logs/RunDest.5479919*.out
# ijob -A berglandlab -c20 -p standard --mem=64G


module load apptainer/1.3.4
#apptainer build -F /scratch/aob2x/dest_v3.sif docker://alanbergland/dest_v3:latest

### prep reference genome
 singularity run \
 /scratch/aob2x/dest_v3.sif  \
 /project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_1.fastq.gz \
 /project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_2.fastq.gz \
 DE_Bad_Bro_1_2020-07-16 \
 /scratch/aob2x/dest_v3_output/ \
 --reference_genome /project/berglandlab/Dmel_genomic_resources/References/DESTv3_dmelholo/holo.dmel_6.54.dsim_3.1.dest3.fa \
 --focal_file /home/aob2x/DESTv3/examples/mapping/focalFile \
 --prep_reference 1 \
 --do_map 0 \
 --do_pileup 0 \
 --do_poolsnp 0 \
 --do_snape 0 \
 --do_cleanup 0



singularity run \
/scratch/aob2x/dest_v3.sif  \
/project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_1.fastq.gz \
/project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_2.fastq.gz \
DE_Bad_Bro_1_2020-07-16 \
/scratch/aob2x/dest_v3_output/ \
--threads 20 \
--max-cov 0.95 \
--min-cov 4 \
--base-quality-threshold 25 \
--num-flies 40 \
--reference_genome /scratch/aob2x/tmpRef/holo_dmel_6.12.fa \
--focal_file /scratch/aob2x/tmpRef/focalFile.csv \
--prep_reference 0 \
--do_map 0 \
--do_pileup 0 \
--do_poolsnp 1 \
--do_snape 1 \
--do_cleanup 0

### foo

# singularity shell /scratch/aob2x/dest_v3.sif
chmod +x ~/DESTv3/mappingPipeline/scripts/fq_to_sync_pipeline.v3.0.0.sh

~/DESTv3/mappingPipeline/scripts/fq_to_sync_pipeline.v3.0.0.sh \
/project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_1.fastq.gz \
/project/berglandlab/DEST/raw_reads/DrosEU_3_Jan2023/DrosEu-194_2.fastq.gz \
DE_Bad_Bro_1_2020-07-16 \
/scratch/aob2x/dest_v3_output/ \
--threads 20 \
--max-cov 0.95 \
--min-cov 4 \
--base-quality-threshold 25 \
--num-flies 40 \
--reference_genome /scratch/aob2x/tmpRef/holo_dmel_6.12.fa \
--focal_file /scratch/aob2x/tmpRef/focalFile.csv \
--prep_reference 0 \
--do_map 0 \
--do_pileup 0 \
--do_poolsnp 1 \
--do_snape 1 \
--do_cleanup 0
