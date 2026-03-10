#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

trap 'rm -rf ${tmpdir}' EXIT

module purge
#module load gcc/7.1.0 openmpi/3.1.4
#module load htslib bcftools parallel intel/18.0 intelmpi/18.0 mvapich2/2.3.1 R/3.6.3 python/3.6.6 vcftools/0.1.16
#module load htslib/1.10.2 bcftools/1.9 parallel/20200322 intel/18.0 intelmpi/18.0 R/3.6.3 python/3.6.6 vcftools/0.1.16
module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 vcftools/0.1.16 R/4.3.1
module load bedtools/2.30.0

### r, mvapch, parallel


## Run params
  popSet=${1}
  method=${2}
  species=${3}  # new param
  maf=${4}
  mac=${5}
  version=${6}
  wd=${7}
  script_dir=${8}
  pipeline_output=${9}
  jobid=${10}
  job=$( echo $jobid | sed 's/\(.*\)_/\1,/; s/\(.*\)_/\1,/')  # replace last two "_" with ","
  bamlist=${11}    # new param

## working & temp directory
  outdir="${wd}/sub_vcfs" #### outdir=${wd}"/sub_vcfs"
  if [ ! -d $outdir ]; then
    mkdir $outdir
  fi

## print names of sunc files
### full list
  echo "jobid is " $jobid
  echo "job: "${job}
  echo "pipeline_output: "${pipeline_output}
  cat $bamlist

### make names
  names=$( cat $bamlist | awk -F"/" '{print $NF}' | cut -f1 -d\. | tr '\n' ',' | sed 's/,$//g' )
  echo $names

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
    cat ${tmpdir}/allpops.${method}.${species}.sites | python ${script_dir}/PoolSNP/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --miss-frac 0.5 \
    --min-count 0 \
    --min-freq 0 \
    --posterior-prob 0.9 \
    --SNAPE \
    --names $( echo ${names} )  > ${tmpdir}/${jobid}.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf

  elif [[ "${method}"=="PoolSNP" ]]; then
    echo $method

    cat ${tmpdir}/allpops.${method}.${species}.sites | python ${script_dir}/PoolSNP/PoolSnp.py \
    --sync - \
    --min-cov 4 \
    --max-cov 0.95 \
    --min-count ${mac} \
    --min-freq 0.${maf} \
    --miss-frac 0.5 \
    --names $( echo ${names} )  > ${tmpdir}/${jobid}.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf
  fi

### compress and clean up
  echo "compress and clean"
  cat ${tmpdir}/${jobid}.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf | vcf-sort | bgzip -c > ${outdir}/${jobid}.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  tabix -p vcf ${outdir}/${jobid}.${species}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  #rm -fr ${tmpdir} # used bash exit trap instead (line 6)

### done
  echo "done"
