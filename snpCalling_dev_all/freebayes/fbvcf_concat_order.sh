#! /bin/bash
#SBATCH -p workq
#SBATCH --export=ALL

module load bioinfo/Bcftools/1.17

bamlist=$1
chkfile=$2

awk '{n=split($1,tmp,"/");split(tmp[n],tt,"\.");{print tt[1]}}' $bamlist >sample.ord
awk '{print "res_vcf/'${bamlist}'."$1".freebayes.noclump.vcf.gz"}' $chkfile > tmp
awk '{if(FNR==NR){tmp[$1]++}else{if($1 in tmp){print $0}}}' <(ls res_vcf/${bamlist}.*.freebayes.noclump.vcf.gz) tmp > tmp.lst 

bcftools concat -f tmp.lst | bcftools view -S sample.ord -i 'QUAL>20' - -Oz > ${bamlist}.freebayes.noclump.vcf.gz



