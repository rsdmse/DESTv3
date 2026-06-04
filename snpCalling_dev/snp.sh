#!/bin/bash
#SBATCH -A berglandlab
#SBATCH -p standard
#SBATCH --ntasks-per-node=1 # one core
#SBATCH -t 20:00:00 ### 1 hours
#SBATCH -J snp # A single job name for the array
#SBATCH -o sm_test/logs/snp.%A_%a.out # Standard output
#SBATCH -e sm_test/logs/snp.%A_%a.err # Standard error

module purge
ml apptainer

SIF=/scratch/$USER/rs7wz-dest/dest_v3-snp.sif
DEST_DIR=/scratch/$USER/rs7wz-dest/DESTv3
SLURM_DIR=/opt/slurm

cd $DEST_DIR/snpCalling_dev
# unlock
apptainer run $SIF \
	snakemake --profile slurm --unlock

# bind Slurm directories and system libraries
apptainer run -B $SLURM_DIR -B /var/spool/slurm -B /usr/lib64/libmunge.so.2 -B /run/munge \
	--env PREPEND_PATH=$SLURM_DIR/current/bin $SIF \
	snakemake --profile slurm
