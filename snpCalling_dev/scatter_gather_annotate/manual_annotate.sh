#!/bin/bash
#
#SBATCH -J manual_annotate # A single job name for the array
#SBATCH --ntasks-per-node=48 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 12:00:00 ### 1 hours
#SBATCH --mem 40G
#SBATCH -o /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_annotate.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_annotate.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab

### cat /scratch/aob2x/DESTv2_output_SNAPE/logs/runSnakemake.49369837*.err

### sbatch ~/CompEvoBio_modules/utils/snpCalling/scatter_gather_annotate/manual_annotate.sh
### sacct -j 4425471
### cat /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_annotate.4425471*.err
# # ijob -A biol4559-aob2x -c10 -p largemem --mem=40G

module purge

module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 perl/5.40.2 vcftools/0.1.16 bedtools/2.30.0

popSet=all
method=SNAPE
species=sim
maf=001
mac=50
version=14Nov2025_sim
wd=/scratch/aob2x/14Nov2025_sim_dest3
script_dir=~/DESTv3/snpCalling_dev
pipeline_output=/scratch/aob2x/dest_v3_output
reference_genome=/project/berglandlab/Dmel_genomic_resources/References/DESTv3_dmelholo/holo.dmel_6.54.dsim_3.1.dest3.fa
focalFile=/home/aob2x/DESTv3/examples/mapping/focalFile
nJobs=2000
job=${SLURM_ARRAY_TASK_ID}    # job=1
repeatFile=${script_dir}/scatter_gather_annotate/repeat_bed/repeats.sort.bed.gz
#ls -d ${pipeline_output}/*/*${species}.${method}*.sync.gz | grep -v "complete" | grep "masked" > /scratch/aob2x/14Nov2025_sim_dest3/sim_snape.bamlist
bamlist=/scratch/aob2x/14Nov2025_sim_dest3/sim_snape.bamlist
snpEff_species=BDGP6.86
snpEffPath=~/snpEff

export popSet method species maf mac version wd script_dir pipeline_output reference_genome focalFile job repeatFile bamList

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
   java -jar ~/snpEff/snpEff.jar \
   eff \
   ${snpEff_species} - > \
   ${wd}/dest.${species}.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf

echo "make GDS"
   Rscript --vanilla ~/CompEvoBio_modules/utils/snpCalling/scatter_gather_annotate/gds2vcf.R ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf

echo "bgzip & tabix"
  bgzip -@10 -c ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf > ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf.gz
  tabix -p vcf ${wd}/dest.${popSet}.${method}.${maf}.${mac}.${version}.norep.ann.vcf.gz
