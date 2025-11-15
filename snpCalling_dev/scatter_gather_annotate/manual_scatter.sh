#!/usr/bin/env bash

#SBATCH -J manual_scatter # A single job name for the array
#SBATCH --ntasks-per-node=8 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 4:00:00 ### 1 hours
#SBATCH --mem 64G
#SBATCH -o /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_gather.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_gather.%A_%a.err # Standard error
#SBATCH -p standard
#SBATCH --account berglandlab_standard


# ijob -A berglandlab -c10 -p standard --mem=24G
# sbatch --array=1-1002 ~/CompEvoBio_modules/utils/snpCalling/scatter_gather_annotate/manual_scatter.sh
# sacct -j 4287499 | grep -v "COMPLE"
# cat /scratch/aob2x/29Sept2025_ExpEvo/logs/manual_gather.4243100_3.out


module purge
trap 'rm -rf ${tmpdir}' EXIT

#module load htslib bcftools parallel intel/18.0 intelmpi/18.0 mvapich2/2.3.1 R/3.6.3 python/3.6.6 vcftools/0.1.16
#module load htslib/1.10.2 bcftools/1.9 parallel/20200322 intel/18.0 intelmpi/18.0 R/3.6.3 python/3.6.6 vcftools/0.1.16
module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 vcftools/0.1.16 R/4.3.1
module load bedtools/2.30.0


## Run params
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

  #ls -d ${pipeline_output}/*/*${species}.${method}*.sync.gz | grep -v "complete" | grep "masked" > /scratch/aob2x/14Nov2025_sim_dest3/sim_snape.bamlist
  bamlist=/scratch/aob2x/14Nov2025_sim_dest3/sim_snape.bamlist

## working & temp directory
  outdir="${wd}/sub_vcfs" #### outdir=${wd}"/sub_vcfs"
  if [ ! -d $outdir ]; then
    mkdir $outdir
  fi

## print names of sunc files
### full list
  echo "job: "${job}
  echo "pipeline_output: "${pipeline_output}
  cat $bamlist

### make names
  names=$( cat $bamlist | awk -F"/" '{print $NF}' | cut -f1 -d\. | tr '\n' ',' | sed 's/,$//g' )
  echo $names

### make Jobs file
  if [ ! -f ${reference_genome}.fai.${species}.${nJobs}.jobs ]; then
    Rscript --vanilla ${script_dir}/scatter_gather_annotate/makeJobs.R ${reference_genome}.fai ${focalFile} ${species} ${nJobs}
  fi
  head ${reference_genome}.fai.${species}.${nJobs}.jobs

## get job
  #cat ${script_dir}/scatter_gather_annotate/jobs_genome.csv
  job=$( cat ${reference_genome}.fai.${species}.${nJobs}.jobs | sed "${job}q;d" )
  jobid=$( echo ${job} | sed 's/,/_/g' )
  echo "jobid is " $jobid
  echo "job is " $job

## set up RAM disk
  [ ! -d /dev/shm/$USER/ ] && mkdir -p /dev/shm/$USER/  # added -p flag to avoid error when it isn't needed
  [ ! -d /dev/shm/$USER/${SLURM_JOB_ID} ] && mkdir /dev/shm/$USER/${SLURM_JOB_ID}
  tmpdir=/dev/shm/$USER/${SLURM_JOB_ID}

  echo "Temp dir is $tmpdir"

## get sub section
  subsection () {
    #set +e
    syncFile=${1}
    job=${2}
    jobid=$( echo ${job} | sed 's/,/_/g' )
    tmpdir=${3}

    pop=$( echo ${syncFile} | rev | cut -f1 -d'/' | rev | sed 's/.masked.sync.gz//g' )

    chr=$( echo $job | cut -f1 -d',' )
    start=$( echo $job | cut -f2 -d',' )
    stop=$( echo $job | cut -f3 -d',' )

    echo ${pop}_${jobid}

    #touch ${syncFile}.tbi

    tabix -b 2 -s 1 -e 2 \
    ${syncFile} \
    ${chr}:${start}-${stop} > ${tmpdir}/${pop}_${jobid}
    #set -e

  }
  export -f subsection

  #echo "subset"
  #if [[ "${method}" == "SNAPE" && "${popSet}" == "PoolSeq" ]]; then
  #  echo "SNAPE" ${method}
  #  parallel -j 4 subsection ::: $( ls ${pipeline_output}/*/*/*.masked.sync.gz | tr '  ' '\n' | grep "SNAPE" | grep "monomorphic" ) ::: ${job} ::: ${tmpdir}
  #elif [[ "${method}" == "PoolSNP" && "${popSet}" == "all" ]]; then
  #  echo "PoolSNP" ${method}
  #  parallel -j 4 subsection ::: $( ls ${pipeline_output}/*/*/*.masked.sync.gz | tr '  ' '\n' | grep -v "SNAPE" ) ::: ${job} ::: ${tmpdir}
  #elif [[ "${method}" == "PoolSNP" && "${popSet}" == "PoolSeq" ]]; then
  #  echo "PoolSNP" ${method}
  #  parallel -j 4 subsection ::: $( ls ${pipeline_output}/*/*/*.masked.sync.gz | tr '  ' '\n' | grep -v "SNAPE" | grep -v "DGN" ) ::: ${job} ::: ${tmpdir}
  #fi

  echo "Species: "${species}"; Method: "${method}
  parallel -j 4 subsection ::: $( cat ${bamlist} ) ::: ${job} ::: ${tmpdir}

### paste function
  echo "paste"
  Rscript --no-save --no-restore ${script_dir}/scatter_gather_annotate/paste.R ${job} ${tmpdir} ${method} ${species}

### run through SNP calling
  echo "SNP calling"

  if [[ "${method}" == "SNAPE" ]]; then
    echo $method
    cat ${tmpdir}/allpops.${method}.sites | python ${script_dir}/PoolSNP/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --miss-frac 0.5 \
    --min-count 0 \
    --min-freq 0 \
    --posterior-prob 0.9 \
    --SNAPE \
    --names $( echo ${names} )  > ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf

  elif [[ "${method}"=="PoolSNP" ]]; then
    echo $method

    cat ${tmpdir}/allpops.${method}.sites | python ${script_dir}/PoolSNP/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --min-count ${mac} \
    --min-freq 0.${maf} \
    --miss-frac 0.5 \
    --names $( echo ${names} )  > ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf
  fi

### compress and clean up
  echo "compress and clean"
  # cp ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf
  # cat ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf | bgzip -c > ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz
   cat ${tmpdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf | vcf-sort | bgzip -c > ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  tabix -p vcf ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz


  bedtools intersect -sorted -v -header \
  -b ${script_dir}/scatter_gather_annotate/repeat_bed/repeats.sort.bed.gz \
  -a ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz |
  bgzip -c > \
  ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

  tabix -p vcf ${outdir}/${jobid}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

  #echo "vcf -> bcf "
  #bcftools view -Ou ${tmpdir}/${jobid}.vcf.gz > ${outdir}/${jobid}.bcf

  rm -fr ${tmpdir} # used bash exit trap instead (line 6)

### done
  echo "done"
