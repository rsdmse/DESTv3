Running:

snakemake command line options: https://snakemake.readthedocs.io/en/stable/executing/cli.html

METHOD: use "fb" (freebayes) or "poolsnp_snape" to reference the correct slurm profile

1. Create working directory and logs directory (working_directory/logs)
mkdir /scratch/kjl5t/sm_test
mkdir /scratch/kjl5t/sm_test/logs

2. Dry Run 
-n: dry run 
-f: Force the execution of the selected target or the first rule regardless of already created output.

module load gcc/11.4.0 openmpi/4.1.4 python/3.11.4 snakemake/9.8.1 R/4.3.1
cd ~/DAC/Bergland/DESTv3/snpCalling_dev_all
snakemake -f --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_all/slurm_METHOD -n

3. Unlock working directory and print summary
--unlock: Remove a lock on the working directory (could have been left by a crashed/terminated run) 
-S: Print a summary of all files created by the workflow.

snakemake --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_all/slurm_METHOD --unlock
snakemake -Sf

4. Run workflow

module load gcc/11.4.0 openmpi/4.1.4 python/3.11.4 snakemake/9.8.1 R/4.3.1
cd ~/DAC/Bergland/DESTv3/snpCalling_dev_all
snakemake --profile ~/DAC/Bergland/DESTv3/snpCalling_dev_all/slurm_METHOD --unlock
sbatch ~/DAC/Bergland/DESTv3/snpCalling_dev_all/runSnakemake.sh METHOD
