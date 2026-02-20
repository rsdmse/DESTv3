#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

### #
### #SBATCH -J manual_annotate # A single job name for the array
### #SBATCH --ntasks-per-node=20 # one core
### #SBATCH -N 1 # on one node
### #SBATCH -t 14:00:00 ### 1 hours
### #SBATCH --mem 40G
### #SBATCH -o /scratch/aob2x/compBio_SNP_25Sept2023/logs/manual_annotate.%A_%a.out # Standard output
### #SBATCH -e /scratch/aob2x/compBio_SNP_25Sept2023/logs/manual_annotate.%A_%a.err # Standard error
### #SBATCH -p standard
### #SBATCH --account biol4559-aob2x
###
### ### cat /scratch/aob2x/DESTv2_output_SNAPE/logs/runSnakemake.49369837*.err
###
### ### sbatch /scratch/aob2x/CompEvoBio_modules/utils/snpCalling/scatter_gather_annotate/manual_annotate.sh
### ### sacct -j 49432588
### ### cat /scratch/aob2x/compBio_SNP_25Sept2023/logs/manual_annotate*.out

module purge

#module load  htslib/1.10.2 bcftools/1.9 intel/18.0 intelmpi/18.0 parallel/20200322 R/3.6.3 samtools vcftools

module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 perl/5.40.2 vcftools/0.1.16 bedtools/2.30.0 R/4.3.1

echo "R_LIBS_USER=~/R/goolf/4.3" > ~/.Renviron


popSet=${1}
method=${2}
species=${3}
maf=${4}
mac=${5}
version=${6}
wd=${7}
snpEffPath=${8}
focalFile=${9}
script_dir=${10}
repeatFile=${script_dir}/scatter_gather_annotate/repeat_bed/repeats.sort.bed.gz
snpEff_species=${11}

export popSet method species maf mac version focalFile repeatFile

cd ${wd}

  bcf_outdir="${wd}/sub_bcf"
  if [ ! -d $bcf_outdir ]; then
      mkdir $bcf_outdir
  fi
export bcf_outdir

echo "no rep & index"

  noRepIndex () {
    chr=${1}
    bedtools intersect -sorted -v -header \
    -b ${repeatFile} \
    -a ${bcf_outdir}/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz |
    bgzip -c > \
    ${bcf_outdir}/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

    bcftools index -f ${bcf_outdir}/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz
  }
  export -f noRepIndex

  parallel -j5 noRepIndex ::: $( cat ${focalFile} | grep "${species}" | cut -f2 -d',' )

 echo "concat"
   ls -d ${wd}/sub_bcf/dest.${species}.*.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz | grep -E $( cat ${focalFile} | grep "${species}" | cut -f2 -d',' | tr '\n' '|' ) > \
   ${wd}/sub_bcf/vcf_order.genome

   bcftools concat \
   -f ${wd}/sub_bcf/vcf_order.genome \
   -O z \
   --threads 10 \
   -o ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

   tabix -p vcf ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz


 echo "convert to vcf & annotate"
   bcftools view \
   --threads 48 \
   ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz | \
   java -jar ${snpEffPath}/snpEff.jar \
   eff \
   ${snpEff_species} - > \
   ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf

echo "make GDS"
   Rscript --vanilla ${script_dir}/scatter_gather_annotate/vcf2gds.R ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf

echo "bgzip & tabix"
  bgzip -@10 -c ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf > ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf.gz
  tabix -p vcf ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf.gz

