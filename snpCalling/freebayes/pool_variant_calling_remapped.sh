#! /bin/bash
#SBATCH -p workq
#SBATCH --mem=32G
#SBATCH --export=ALL

module load bioinfo/freebayes/1.3.6

BAMLIST=$1
REGION=$2
#PATH_TO_ASSEMBLY="/home/nrode/work/DEST_PHENO/assembly/holo_dmel_6.12.fa"
PATH_TO_ASSEMBLY="/work/project/gandhi/DEST_PHENO/assembly/holo_dmel_6.12_wosim.fa"

freebayes -f $PATH_TO_ASSEMBLY -L $BAMLIST  -r $REGION -K -C 1 -F 0.01 -G 5 -E -1 --limit-coverage 500 -n 4 -m 30 -q 20 |gzip -c > res_vcf/${BAMLIST}.${REGION}.freebayes.noclump.vcf.gz
#freebayes -f $PATH_TO_ASSEMBLY -L $BAMLIST  -r $REGION -K -E -1 -C 1 -F 0.01 -G 5 --limit-coverage 500 -n 4 -m 30 -q 20 |gzip -c > res_vcf/${BAMLIST}.${REGION}.freebayes.woclumping.vcf.gz

##########################
###DETAIL OPTIONS CHOISIES
##########################

# -K --pooled-continuous : Output all alleles which pass input filters, regardles of genotyping outcome or model.
## option la moins couteuse en temps/memoire... car si on utilise pool-discrete il faut lui specifier une taille haploide de pool (cf cnv-map) mais surtout 
## il calcule les vraisemblances pour cahque configuration possible ce qui devient tres	long en	temps de calcul	(comme dans le cas de GATK HaplotypeCaller option -ploidy qu'il vaut mieux reduire)

# -F --min-alternate-fraction N : Require at least this fraction of observations supporting an alternate allele within a single individual in the in order to evaluate the position.  default: 0.05
## Dans le cas de PoolSeq il vaut mieux reduire pour ne pas penaliser les alleles rares presents dans un pool (avec la valeur par defaut, tout varaint present represente par <5% des lectures dans le pool
## serait ignore (cela dit s'il etait frequent dans un autre pool il pourrait etre comptabilise

# -C --min-alternate-count N : Require at least this count of observations supporting an alternate allele within a single individual in order to evaluate the position.  default: 2
## Reduit à 1 pour les meme raison que pour -F

# -G --min-alternate-total N : Require at least this count of observations supporting an alternate allele within the TOTAL population in order to use the allele in analysis.  default: 1
## Augmenté à 5: Vu qu'on applique à de nombreux pools generalement, evite de se trimbaler des alleles ultra rares, vraisemblablement des erreurs de sequencages =>reduction des couts computationnels
## Attention cependant peut avoir un impact pour des methodes basees sur SFS

# --limit-coverage N Downsample per-sample coverage to this level if greater than this coverage. default: no limit
## Mis à 500 ici (bien au dessus de nos couvertures habituelles). Peut avoir un impact sur l'identification des variants dans les sequences repetees, Attention aussi si on s'interesse à la Mito ou aux endosymbiontes?

# -m --min-mapping-quality Q : Exclude alignments from analysis if they have a mapping quality less than Q.  default: 1
# -q --min-base-quality Q : Exclude alleles from analysis if their supporting base quality is less than Q.  default: 0
## Criteres classiques de qualite (Note: pet etre a reajuster si on fait de la recalibration des Base Quality BQSR)?

# -n --use-best-n-alleles N : Evaluate only the best N SNP alleles, ranked by sum of supporting quality scores.  (Set to 0 to use all; default: all)
## Reduit a 4 (cf recommandation pour reduction cout computationnel). Attention cependant car les autres alleles ne sont tout simplement pas considere (i.e., le DP reel peut varier du DP realise, i.e., somme des couvertures des alleles reportes)
## La plupart du temps, on ne retiendra que les bi-allelique (ou les alleles tres peu couverts seront vires: cf poolfstat)
## (dans GATK HaplotypeCaller c'est 7 par defaut car --max-alternate-alleles 6)

# --strict-vcf Generate strict VCF format (FORMAT/GQ will be an int)
# Les Genotype QUality (pas utile ici puisque pooled-continuous) sont donnees par defaut en log10 scale likelihood (=>alourdi le fichier output)

#################
#REMARQUES
################

#De maniere generale les likelhood ou les GQ sont donnees en log10 scale (et pas en Phred). Dans le cas des GQ:
# --strict-vcf Generate strict VCF format (FORMAT/GQ will be an int)
# Les Genotype QUality (pas utile ici puisque pooled-continuous) sont donnees par defaut en log10 scale likelihood (=>alourdi le fichier output)




#Lorsque'on parrallelise analyse d'une region, ca ne sert a rien de faire overlapper les chunks overlapping car il tient compte de lenvironnement au dela de la limite
#Par exemple (dans test preliminaire):
#gunzip -c list.bam.dedup.chr1:39999000-41000000.freebayes.vcf.gz |grep -v "^#" |awk '$2<=40000000' - |awk '{print $1,$2,$3,$4,$5,$6,$7}' -
#....
#chr1 39999961 . TCT ACA,TTT,ACT 1.34697e-06 .
#chr1 39999967 . G A 7.44002e-09 .
#chr1 39999976 . A G 70.586 .
#chr1 39999979 . AAGAGTTTTTTTTTATAAT AAGAGGTTTTTTTTTATAAT,AAGAGTTTTTTTTTTATAAT,AAGAGGTTTTTTTTTTATAAT,AAGAGGTTTTTTTTATAAT 9817.08 .
#chr1 39999999 . TTCCTCCATGTGGGC TTCCTACATCTGGGC,TTCCTCCATCTGGAT,TTCCTCCATCTGGGC 6465.96 .

#gunzip -c list.bam.dedup.chr1:38999000-40000000.freebayes.vcf.gz |tail -3 |awk '{print $1,$2,$4,$5,$6,length($4),length($5)}' -
#chr1 39999976 A G 70.586 1 1
#chr1 39999979 AAGAGTTTTTTTTTATAAT AAGAGGTTTTTTTTTATAAT,AAGAGTTTTTTTTTTATAAT,AAGAGGTTTTTTTTTTATAAT,AAGAGGTTTTTTTTATAAT 9816.32 19 83
#chr1 39999999 TTCCTCCATGTGGGC TTCCTACATCTGGGC,TTCCTCCATCTGGAT,TTCCTCCATCTGGGC 6464.2 15 47


##########################
#### INFO et FORMAT field du vcf
#########################

##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of samples with data">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total read depth at the locus">
##INFO=<ID=DPB,Number=1,Type=Float,Description="Total read depth per bp at the locus; bases in reads overlapping / bases in haplotype">
##INFO=<ID=AC,Number=A,Type=Integer,Description="Total number of alternate alleles in called genotypes">
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
##INFO=<ID=AF,Number=A,Type=Float,Description="Estimated allele frequency in the range (0,1]">
##INFO=<ID=RO,Number=1,Type=Integer,Description="Count of full observations of the reference haplotype.">
##INFO=<ID=AO,Number=A,Type=Integer,Description="Count of full observations of this alternate haplotype.">
##INFO=<ID=PRO,Number=1,Type=Float,Description="Reference allele observation count, with partial observations recorded fractionally">
##INFO=<ID=PAO,Number=A,Type=Float,Description="Alternate allele observations, with partial observations recorded fractionally">
##INFO=<ID=QR,Number=1,Type=Integer,Description="Reference allele quality sum in phred">
##INFO=<ID=QA,Number=A,Type=Integer,Description="Alternate allele quality sum in phred">
##INFO=<ID=PQR,Number=1,Type=Float,Description="Reference allele quality sum in phred for partial observations">
##INFO=<ID=PQA,Number=A,Type=Float,Description="Alternate allele quality sum in phred for partial observations">
##INFO=<ID=SRF,Number=1,Type=Integer,Description="Number of reference observations on the forward strand">
##INFO=<ID=SRR,Number=1,Type=Integer,Description="Number of reference observations on the reverse strand">
##INFO=<ID=SAF,Number=A,Type=Integer,Description="Number of alternate observations on the forward strand">
##INFO=<ID=SAR,Number=A,Type=Integer,Description="Number of alternate observations on the reverse strand">
##INFO=<ID=SRP,Number=1,Type=Float,Description="Strand balance probability for the reference allele: Phred-scaled upper-bounds estimate of the probability of observing the deviation between SRF and SRR given E(SRF/SRR) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=SAP,Number=A,Type=Float,Description="Strand balance probability for the alternate allele: Phred-scaled upper-bounds estimate of the probability of observing the deviation between SAF and SAR given E(SAF/SAR) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=AB,Number=A,Type=Float,Description="Allele balance at heterozygous sites: a number between 0 and 1 representing the ratio of reads showing the reference allele to all reads, considering only reads from individuals called as heterozygous">
##INFO=<ID=ABP,Number=A,Type=Float,Description="Allele balance probability at heterozygous sites: Phred-scaled upper-bounds estimate of the probability of observing the deviation between ABR and ABA given E(ABR/ABA) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=RUN,Number=A,Type=Integer,Description="Run length: the number of consecutive repeats of the alternate allele in the reference genome">
##INFO=<ID=RPP,Number=A,Type=Float,Description="Read Placement Probability: Phred-scaled upper-bounds estimate of the probability of observing the deviation between RPL and RPR given E(RPL/RPR) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=RPPR,Number=1,Type=Float,Description="Read Placement Probability for reference observations: Phred-scaled upper-bounds estimate of the probability of observing the deviation between RPL and RPR given E(RPL/RPR) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=RPL,Number=A,Type=Float,Description="Reads Placed Left: number of reads supporting the alternate balanced to the left (5') of the alternate allele">
##INFO=<ID=RPR,Number=A,Type=Float,Description="Reads Placed Right: number of reads supporting the alternate balanced to the right (3') of the alternate allele">
##INFO=<ID=EPP,Number=A,Type=Float,Description="End Placement Probability: Phred-scaled upper-bounds estimate of the probability of observing the deviation between EL and ER given E(EL/ER) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=EPPR,Number=1,Type=Float,Description="End Placement Probability for reference observations: Phred-scaled upper-bounds estimate of the probability of observing the deviation between EL and ER given E(EL/ER) ~ 0.5, derived using Hoeffding's inequality">
##INFO=<ID=DPRA,Number=A,Type=Float,Description="Alternate allele depth ratio.  Ratio between depth in samples with each called alternate allele and those without.">
##INFO=<ID=ODDS,Number=1,Type=Float,Description="The log odds ratio of the best genotype combination to the second-best.">
##INFO=<ID=GTI,Number=1,Type=Integer,Description="Number of genotyping iterations required to reach convergence or bailout.">
##INFO=<ID=TYPE,Number=A,Type=String,Description="The type of allele, either snp, mnp, ins, del, or complex.">
##INFO=<ID=CIGAR,Number=A,Type=String,Description="The extended CIGAR representation of each alternate allele, with the exception that '=' is replaced by 'M' to ease VCF parsing.  Note that INDEL alleles do not have the first matched base (which is provided by default, per the spec) referred to by the CIGAR.">
##INFO=<ID=NUMALT,Number=1,Type=Integer,Description="Number of unique non-reference alleles in called genotypes at this position.">
##INFO=<ID=MEANALT,Number=A,Type=Float,Description="Mean number of unique non-reference allele observations per sample with the corresponding alternate alleles.">
##INFO=<ID=LEN,Number=A,Type=Integer,Description="allele length">
##INFO=<ID=MQM,Number=A,Type=Float,Description="Mean mapping quality of observed alternate alleles">
##INFO=<ID=MQMR,Number=1,Type=Float,Description="Mean mapping quality of observed reference alleles">
##INFO=<ID=PAIRED,Number=A,Type=Float,Description="Proportion of observed alternate alleles which are supported by properly paired read fragments">
##INFO=<ID=PAIREDR,Number=1,Type=Float,Description="Proportion of observed reference alleles which are supported by properly paired read fragments">
##INFO=<ID=MIN_DP,Number=1,Type=Integer,Description="Minimum depth in gVCF output block.">
##INFO=<ID=END,Number=1,Type=Integer,Description="Last position (inclusive) in gVCF output record.">
##INFO=<ID=technology.ILLUMINA,Number=A,Type=Float,Description="Fraction of observations supporting the alternate observed in reads from ILLUMINA">


##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=GQ,Number=1,Type=Float,Description="Genotype Quality, the Phred-scaled marginal (or unconditional) probability of the called genotype">
##FORMAT=<ID=GL,Number=G,Type=Float,Description="Genotype Likelihood, log10-scaled likelihoods of the data given the called genotype for each possible genotype generated from the reference and alternate alleles given the sample ploidy">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Number of observation for each allele">
##FORMAT=<ID=RO,Number=1,Type=Integer,Description="Reference allele observation count">
##FORMAT=<ID=QR,Number=1,Type=Integer,Description="Sum of quality of the reference observations">
##FORMAT=<ID=AO,Number=A,Type=Integer,Description="Alternate allele observation count">
##FORMAT=<ID=QA,Number=A,Type=Integer,Description="Sum of quality of the alternate observations">
##FORMAT=<ID=MIN_DP,Number=1,Type=Integer,Description="Minimum depth in gVCF output block.">

