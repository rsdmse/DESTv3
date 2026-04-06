#!/bin/bash
#
#SBATCH -J runSnakemake # A single job name for the array
#SBATCH --ntasks-per-node=1 # one core
#SBATCH --cpus-per-task=1 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 3-00:00:00 ### 3 days
#SBATCH --mem 1G
#SBATCH -o /scratch/kjl5t/DEST/logs/runSnakemake.%A_%a.out # Standard output
#SBATCH -e /scratch/kjl5t/DEST/logs/runSnakemake.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account hpc_build

METHOD=${1}

if [ "${METHOD}" == "fb" ]; then
    echo $METHOD
    module load gcc/11.4.0 openmpi/4.1.4 python/3.11.4 snakemake/9.8.1 
    snakemake --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_all/slurm_fb
else
    # PoolSNP or SNAPE
    echo $METHOD
    module load gcc/11.4.0 openmpi/4.1.4 python/3.11.4 snakemake/9.8.1 R/4.3.1
    snakemake --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_all/slurm_poolsnp_snape
fi





