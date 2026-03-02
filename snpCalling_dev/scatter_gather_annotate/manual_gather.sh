#!/bin/bash
#
#SBATCH -J manual_gather # A single job name for the array
#SBATCH --ntasks-per-node=48 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 14:00:00 ### 1 hours
#SBATCH --mem 20G
#SBATCH -o /scratch/aob2x/29Sept2025_ExpEvo/manual_gather.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_gather.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

### sbatch ~/DESTv3/snpCalling_dev/scatter_gather_annotate/manual_gather.sh
### sacct -j 5783940
### cat /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_gather.5783940_1.err
### cat /scratch/aob2x/compBio_SNP_25Sept2023/logs/manual_gather
### cd /scratch/aob2x/compBio_SNP_25Sept2023

# ijob -A berglandlab -c20 -p standard --mem=48G


module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 perl/5.40.2 vcftools/0.1.16 bedtools/2.30.0
focalFile=/home/aob2x/DESTv3/examples/mapping/focalFile
species=sim

concatVCF() {

  popSet=all
  method=SNAPE
  species=sim
  maf=001
  mac=50
  version=20Nov2025_sim
  wd=/scratch/aob2x/${version}_dest3
  script_dir=~/DESTv3/snpCalling_dev
  pipeline_output=/scratch/aob2x/dest_v3_output
  reference_genome=/project/berglandlab/Dmel_genomic_resources/References/DESTv3_dmelholo/holo.dmel_6.54.dsim_3.1.dest3.fa
  focalFile=/home/aob2x/DESTv3/examples/mapping/focalFile
  nJobs=2000
  job=${SLURM_ARRAY_TASK_ID}    # job=1
  repeatFile=${script_dir}/scatter_gather_annotate/repeat_bed/repeats.sort.bed.gz
  #ls -d ${pipeline_output}/*/*${species}.${method}*.sync.gz | grep -v "complete" | grep "masked" > /scratch/aob2x/sim_snape.bamlist
  bamlist=/scratch/aob2x/sim_snape.bamlist

  # chr=sim_3R

  chr=${1}

  echo "Chromosome: $chr"

  bcf_outdir="${wd}/sub_bcf"
  if [ ! -d $bcf_outdir ]; then
      mkdir $bcf_outdir
  fi

  outdir=$wd/sub_vcfs
  cd ${wd}

  echo "generate list"
  #ls -d *.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz | grep '^${chr}_' | sort -t"_" -k2n,2 -k4g,4 \
  #> $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort


  ls -d ${outdir}/*.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz | \
  rev | cut -f1 -d '/' |rev | grep -E "^${chr}_" | sort -t"_" -k2n,2 -k4g,4 | \
  sed "s|^|$outdir/|g" > $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort

  if [ -f $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort ]; then
    rm $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort
  fi

  touch $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort
  while IFS= read -r line; do
    # line=/scratch/aob2x/20Nov2025_sim_dest3/sub_vcfs/sim_3R_121074_181610.sim.all.SNAPE.001.50.20Nov2025_sim.vcf.gz
    nLines=$( zcat $line | head -n 500 | grep -A1 "#CHROM" | wc -l )
    #echo $nLines
    if [ "$nLines" -eq "2" ]; then
      echo $line >> $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort
    fi
  done < $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort

  cat $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort |
  sort -t"_" -k2n,2 -k4g,4 > \
  $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort.sort


  wc -l $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort
  wc -l $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort
  wc -l $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort.sort

  # less -S $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort


  echo "Concatenating"

  bcftools concat \
  -f $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.clean.sort \
  -O z \
  -n \
  --threads 40 \
  -o $bcf_outdir/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  # vcf-concat \
  # -f $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort \
  # -s | \
  # bgzip -c > $bcf_outdir/dest.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

  tabix -p vcf $bcf_outdir/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz


}
export -f concatVCF

parallel -j1 concatVCF ::: $( cat ${focalFile} | grep "${species}" | cut -f2 -d',' )
#parallel -j1 concatVCF ::: sim_3R

#parallel -j8 concatVCF ::: 3L
