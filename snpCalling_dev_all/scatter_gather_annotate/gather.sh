#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

module purge

#module load htslib bcftools parallel intel/18.0 intelmpi/18.0 mvapich2/2.3.1 R/3.6.3 python/3.6.6 vcftools/0.1.16
#module load htslib/1.10.2 bcftools/1.9 parallel/20200322 intel/18.0 intelmpi/18.0 R/3.6.3 python/3.6.6 vcftools/0.1.16
module load htslib/1.17  bcftools/1.17 parallel/20250722 gcc/11.4.0 openmpi/4.1.4 python/3.11.4 perl/5.40.2 vcftools/0.1.16 bedtools/2.30.0


popSet=${1}
method=${2}
species=${3}
maf=${4}
mac=${5}
version=${6}
wd=${7}
chr=${8}

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

  # less -S $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort


echo "Concatenating"

bcftools concat \
  -f $outdir/vcfs_order.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort \
  -O z \
  -n \
  --threads 48 \
  -o $bcf_outdir/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz

  # vcf-concat \
  # -f $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort \
  # -s | \
  # bgzip -c > $bcf_outdir/dest.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz

  tabix -p vcf $bcf_outdir/dest.${species}.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.vcf.gz



# old
#echo "Concatenating"

#bcftools concat \
#  -f $outdir/vcfs_order.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.sort \
#  -O z \
#  --naive-force \
#  -o $bcf_outdir/dest.${chr}.${popSet}.${method}.${maf}.${mac}.${version}.norep.vcf.gz
