# ijob -A berglandlab -c40 -p standard --mem=100G
# module load gcc/7.1.0 openmpi/3.1.4 R/3.6.3; R

library(SeqArray)

#vcf.fn="/project/berglandlab/Dmel_Single_Individuals/Phased_Whatshap_only/CM_AB2016_PE2018_Dmel_dm6.whatshapp.noSR.vcf.gz"

args = commandArgs(trailingOnly=TRUE)
vcf.fn=args[[1]]
nCores=as.numeric(args[[2]])
gds.fn=gsub(".vcf", ".gds", vcf.fn)
gds.fn=gsub(".gz", "", gds.fn)

#vcf.fn=paste(vcf.fn, ".gz", sep="")
seqParallelSetup(cluster=nCores, verbose=TRUE)

seqVCF2GDS(vcf.fn, gds.fn, storage.option="ZIP_RA", parallel=nCores, verbose=T, optimize=T)



#seqVCF2GDS("/scratch/aob2x/compBio_SNP_25Sept2023/dest.expevo.PoolSNP.001.50.11Oct2023.norep.ann.vcf",
#            "/scratch/aob2x/compBio_SNP_25Sept2023/dest.expevo.PoolSNP.001.50.11Oct2023.norep.ann.gds", storage.option="ZIP_RA", verbose=T, parallel=10, optimize=T)
#
