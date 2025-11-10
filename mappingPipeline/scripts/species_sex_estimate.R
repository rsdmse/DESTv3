args = commandArgs(trailingOnly=TRUE)
focalFile <- args[1]
idxfn <- args[2]
nFlies <- as.numeric(args[3])

library(data.table)

# focalFile="/scratch/aob2x/tmpRef/focalFile.csv"
# idxfn="/scratch/aob2x/dest_v3_output/DE_Bad_Bro_1_2020-07-16/DE_Bad_Bro_1_2020-07-16.original.bam.idxstats"
# nFlies=40

idx <- fread(idxfn, header=F)
ff <- fread(focalFile, header=F)

d <- merge(idx, ff, by.x="V1", by.y="V2")

d.ag <- d[,list(autD=sum(V3.x[V3.y=="A"], na.rm=T)/sum(V2[V3.y=="A"], na.rm=T), sexD=sum(V3.x[V3.y=="S"], na.rm=T)/sum(V2[V3.y=="S"], na.rm=T)), list(V1.y)]
d.ag[,propFemale:=(2-autD/sexD)/(autD/sexD)]
d.ag[,sppProp:=autD/sum(d.ag$autD)]
d.ag[,sppN:=round(nFlies*sppProp)]
d.ag[,autChrN:=2*sppN]
d.ag[,sexChrN:=round((2*propFemale*sppN) + (1-propFemale)*sppN)]

dl <- melt(data=d.ag, id.vars=c("V1.y"), measure.vars=c("autChrN", "sexChrN"))
dl[,variable:=substr(toupper(variable), 0, 1)]
dl <- setnames(dl, c("variable"), c("V3.y"))
ffs <- merge(dl, ff, by.x=c("V1.y", "V3.y"), by.y=c("V1", "V3"), all.y=T)
ffs <- ffs[,c("V1.y", "V2", "V3.y", "value")]
ffs[is.na(value), value:=max(ffs$value, na.rm=T)]
ffs
write.table(ffs, file=paste(idxfn, ".focalFile", sep=""), quote=F, row.names=F, col.names=F, sep=",")


#    nXchr=$( samtools idxstats ${output}/${sample}/${sample}.${prefix}.bam  | awk -v nFlies=${nflies} '
#            BEGIN {
#              autLen=0
#              sexLen=0
#              autRD=0
#              sexRD=0
#            }
#            {
#              if($3>0) {
#                if(!match($0, /X/) && !match($0, /Y/) && !match($0, /mtDNA/) && !match($0, /mitochondrion_genome/)) {
#                  autLen+=$2
#                  autRD+=$3
#                }
#                if(match($0, /X/)) {
#                  sexLen+=$2
#                  sexRD+=$3
#                }
#              }
#            }
#            END {
#              print "autCov: "autRD/autLen  > "/dev/stderr"
#              print "sexCov: "sexRD/sexLen  > "/dev/stderr"
#              print "SR: " (autRD/autLen)/(sexRD/sexLen)  > "/dev/stderr"
#              propFemale=(2-(autRD/autLen)/(sexRD/sexLen))/((autRD/autLen)/(sexRD/sexLen))
#              print "prop Female: " propFemale  > "/dev/stderr"
#              print "nFemales: " propFemale*nFlies  > "/dev/stderr"
#              print "nMales: " (1-propFemale)*nFlies  > "/dev/stderr"
#              print int(2*propFemale*nFlies  + (1-propFemale)*nFlies + .5)
#            }
#            ' )
#    echo "number of estimated X-chromosomes" $nXchr

#    if [[ "$chr" != *"_X"* && "$chr" != *"_Y"* && "$chr" != *"_mtDNA"* ]]; then
#      nChr=$((${nflies}*2))
#    else
#      nChr=${nXchr}
#    fi
