#!/bin/bash
#
#SBATCH -J runSnakemake # A single job name for the array
#SBATCH --cpus-per-task=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 3-00:00:00 ### 3 days
#SBATCH --mem 1G
#SBATCH -o /scratch/kjl5t/DEST/logs/runSnakemake.%A_%a.out # Standard output
#SBATCH -e /scratch/kjl5t/DEST/logs/runSnakemake.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account hpc_build

module load gcc/11.4.0 openmpi/4.1.4 python/3.11.4 snakemake/9.8.1 

#cd ~/Bergland/DESTv3/snpCalling/
snakemake --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_FB/slurm
