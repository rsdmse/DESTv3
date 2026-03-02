# ijob -A biol4020-aob2x -c10 -p standard --mem=40G
# module load gcc/7.1.0 openmpi/3.1.4 R/3.6.3; R

library(SeqArray)


args = commandArgs(trailingOnly=TRUE)
vcf.fn=args[[1]]
gds.fn=gsub(".vcf", ".gds", vcf.fn)

#vcf.fn=paste(vcf.fn, ".gz", sep="")
#vcf.fn="/scratch/aob2x/20Nov2025_sim_dest3/dest.sim.all.SNAPE.001.50.20Nov2025_sim.norep.ann.vcf"
seqParallelSetup(cluster=10, verbose=TRUE)

seqVCF2GDS(vcf.fn, gds.fn, storage.option="ZIP_RA", parallel=5, verbose=T, optimize=T)



#seqVCF2GDS("/scratch/aob2x/compBio_SNP_25Sept2023/dest.expevo.PoolSNP.001.50.11Oct2023.norep.ann.vcf",
#            "/scratch/aob2x/compBio_SNP_25Sept2023/dest.expevo.PoolSNP.001.50.11Oct2023.norep.ann.gds", storage.option="ZIP_RA", verbose=T, parallel=10, optimize=T)
#
