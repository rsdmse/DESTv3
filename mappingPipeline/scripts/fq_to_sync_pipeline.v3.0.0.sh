#!/bin/bash

### Updated by Alan Bergland
## version=3.0
### Oct 20, 2025

check_exit_status () {
  if [ ! "$2" -eq "0" ]; then
    echo "Step $1 failed with exit status $2"
    exit $2
  fi
  echo "Checked step $1"
}

#### DEFAULT parameters
  do_single_end=0
  read1="test_file_1"
  read2="test_file_2"
  sample="default_sample_name"
  output="."
  threads="1"
  max_cov=0.95
  min_cov=10
  theta=0.005
  D=0.01
  priortype="informative"
  fold="unfolded"
  maxsnape=0.9
  nflies=40
  base_quality_threshold=25
  illumina_quality_coding=1.8
  minIndel=5
  prepRef=1
  do_map=1
  do_pileup=1
  do_snape=1
  do_poolsnp=1
  ref_genome="path_to_ref_fasta"
  focalFile="path_to_focalFile_csv"


##################################
### Parse positional arguments ###
##################################
# Credit: https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
  POSITIONAL=()
  while [[ $# -gt 0 ]]
  do
  key="$1"

  case $key in
  	-do_se|--single_end)
  	  do_single_end=1
      shift # past argument
  	  ;;
      -dps|--do_poolsnp)
      do_poolsnp=$2
      shift # past argument
      ;;
      -bq|--base-quality-threshold)
      base_quality_threshold="$2"
      shift # past argument
      shift # past value
      ;;
      -ill|--illumina-quality-coding)
      illumina_quality_coding="$2"
      shift # past argument
      shift # past value
      ;;
      -mindel|--min-indel)
      minIndel="$2"
      shift # past argument
      shift # past value
      ;;
      -tr|--threads)
      threads="$2"
      shift # past argument
      shift # past value
      ;;
      -x|--max-cov)
      max_cov="$2"
      shift # past argument
      shift # past value
      ;;
      -n|--min-cov)
      min_cov="$2"
      shift # past argument
      shift # past value
      ;;
      -h|--help)
      echo "Usage:"
      echo "  singularity run [options] <image> -h          Display this help message."
      echo "  Pair-end reads mode add --sequencing = 'pe'; Single-end mode add --sequencing = 'se'"
      echo "	Pair-end reads mode requires:"
      echo "  singularity run [options] <image> <fastq_file_1_path> <fastq_file_2_path> <sample_name> <output_dir> <num_cores>"
      echo "	Single-end reads mode requires:"
      echo "  singularity run [options] <image> <fastq_file_Single_path> <sample_name> <output_dir> <num_cores>"
      exit 0
      shift # past argument
      ;;
      -t|--theta)
      theta=$2
      shift # past argument
      shift # past value
      ;;
      -D)
      D=$2
      shift # past argument
      shift # past value
      ;;
      -p|--priortype)
      theta=$2
      shift # past argument
      shift # past value
      ;;
      -f|--fold)
      fold=$2
      shift # past argument
      shift # past value
      ;;
      -ms|--maxsnape)
      maxsnape=$2
      shift # past argument
      shift # past value
      ;;
      -nf|--num-flies)
      nflies=$2
      shift # past argument
      shift # past value
      ;;
      -ds|--do_snape)
      do_snape=$2
      shift # past argument
      shift # past value
      ;;
      -ref|--reference_genome)
      ref=$2
      shift # past argument
      shift # past value
      ;;
      -focalFile|--focal_file)
      focalFile=$2
      shift # past argument
      shift # past value
      ;;
      -prepRef|--prep_reference)
      prepRef=$2
      shift # past argument
      shift # past value
      ;;
      -domap|--do_map)
      do_map=$2
      shift # past argument
      shift # past value
      ;;
      -dopileup|--do_pileup)
      do_pileup=$2
      shift # past argument
      shift # past value
      ;;
      *)    # unknown option
      POSITIONAL+=("$1") #save it to an array
      shift
      ;;
  esac
  done

  set -- "${POSITIONAL[@]}"

#######################
### What am I doing ###
#######################
  echo "Prep Reference Genome: "$prepRef
  echo "Map reads: "$do_map
  echo "Do Pool-SNP: "$do_poolsnp
  echo "Do SNAPE: "$do_snape

  if [ $do_single_end -eq "0"  ]; then
    read1=$1; shift
    read2=$1; shift
    sample=$1; shift
    output=$1; shift
  fi

  if [ $do_single_end -eq "1" ]; then
    read1=$1; shift
    sample=$1; shift
    output=$1; shift
  fi

  echo -e "This is DEST v. ${version} \n Parameters as interpreted + those assumed by default --> \n"
  echo -e \
  "pe (0) or se (1)? =" $do_single_end "\n" \
  "r1 =" $read1 "\n" \
  "r2 =" $read2 "\n" \
  "sample name =" $sample "\n" \
  "output =" $output "\n" \
  "number of flies =" $nflies "\n" \
  "cpus =" $threads "\n" \
  "max cov =" $max_cov "\n" \
  "min cov =" $min_cov "\n" \
  "theta =" $theta "\n" \
  "D =" $D "\n" \
  "prior =" $priortype "\n" \
  "folded? =" $fold "\n" \
  "max snape ="$maxsnape "\n" \
  "base quality threshold =" $base_quality_threshold "\n" \
  "illumina quality coding =" $illumina_quality_coding "\n" \
  "minIndel =" $minIndel "\n" \
  "Prep Reference Genome (0 = no; 1 = yes) =" $prepRef "\n" \
  "map reads (0 = no; 1 = yes)=" $do_map "\n" \
  "do pileup? (0 = no; 1 = yes)=" $do_pileup "\n" \
  "do snape? (0 = no; 1 = yes) -->" $do_snape "\n" \
  "do poolsnp? (0 = no; 1 = yes) -->" $do_poolsnp "\n" \
  "reference genome =" $ref "\n" \
  "focal chromosome file=" $focalFile "\n" \

  if [ ! -f "$read1" ] && [ $do_single_end -eq "0"  ]; then
    echo "ERROR: for paired end run"
    echo "ERROR DETAILS: $read1 does not exist"
    exit 1
  fi

  if [ ! -f "$read2" ] && [ $do_single_end -eq "0"  ]; then
    echo "ERROR: for paired end run"
    echo "ERROR DETAILS: $read2 does not exist"
    exit 1
  fi

  if [ ! -f "$read1" ] && [ $do_single_end -eq "1"  ]; then
    echo "ERROR: for single end run"
    echo "ERROR DETAILS: $read1 does not exist"
    exit 1
  fi


################################
### prepare reference genome ###
################################
  ### error handling
    if [ $prepRef -eq "1" ] && [ $do_poolsnp -eq "1" ]; then
      echo "Cannot prep ref and run mapping at once"
      exit 1
    fi

    if [ $prepRef -eq "1" ] && [ $do_snape -eq "1" ]; then
      echo "Cannot prep ref and run mapping at once"
      exit 1
    fi

  #### prep the reference genome
    if [ $prepRef -eq "1" ]; then
      if [ ! -f ${ref}.amb ]; then bwa index ${ref}; fi
      if [ ! -f ${ref}.fai ]; then samtools faidx ${ref}; fi
      if [ ! -f ${ref}.dict ]; then
        refDict=$( echo ${ref} | sed 's/fa/dict/g' )
        java -jar $PICARD CreateSequenceDictionary R=${ref} O=${refDict}
      fi

      while read p; do
         #prefix=mel
         prefix=$( echo $p | cut -f1 -d',')
         echo $prefix
         chrs=$( echo $p | cut -f2 -d',')
         echo $chrs
         refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )
         samtools faidx ${ref} ${chrs} > ${refOut}

         python3 /opt/DESTv3/mappingPipeline/scripts/PickleRef.py \
             --ref ${refOut} \
             --output ${refOut}
      done < ${focalFile}
      exit
    fi

######################################
### do_map? Process and map reads? ###
######################################
  if [ $do_map -eq "1" ]; then

    ### mkdirs
      if [ ! -d $output/$sample/ ]; then
        mkdir -p $output/$sample/
      fi

      if [ ! -d $output/$sample/${sample}_fastqc ]; then
        mkdir $output/$sample/${sample}_fastqc
      fi

      if [ ! -d $output/$sample/${sample}_fastqc/trimmed ]; then
        mkdir $output/$sample/${sample}_fastqc/trimmed
      fi
    ### Single end case
      if [ $do_single_end -eq "1" ]; then
        echo "begin read preparation | Single End Mode"

        fastqc $read1 -o $output/$sample/${sample}_fastqc

        cutadapt \
        -q 18 \
        --minimum-length 25 \
        -o $output/$sample/${sample}.trimmed1.fq.gz \
        -b ACACTCTTTCCCTACACGACGCTCTTCCGATC \
        -O 15 \
        -n 3 \
        --cores=$threads \
        $read1

        check_exit_status "cutadapt" $?

        fastqc $output/$sample/${sample}.trimmed1.fq.gz  -o $output/$sample/${sample}_fastqc/trimmed

        check_exit_status "fastqc" $?
      fi
    ### Paired end case
      if [ $do_single_end -eq "0" ]; then
        echo "begin read preparation | Paired End Mode"

        fastqc $read1 $read2 -o $output/$sample/${sample}_fastqc

        cutadapt \
        -q 18 \
        --minimum-length 25 \
        -o $output/$sample/${sample}.trimmed1.fq.gz \
        -p $output/$sample/${sample}.trimmed2.fq.gz \
        -b ACACTCTTTCCCTACACGACGCTCTTCCGATC \
        -B CAAGCAGAAGACGGCATACGAGAT \
        -O 15 \
        -n 3 \
        --cores=$threads \
        $read1 $read2

        check_exit_status "cutadapt" $?

        fastqc $output/$sample/${sample}.trimmed1.fq.gz $output/$sample/${sample}.trimmed2.fq.gz -o $output/$sample/${sample}_fastqc/trimmed

        check_exit_status "fastqc" $?

        #Automatically uses all available cores
        bbmerge.sh in1=$output/$sample/${sample}.trimmed1.fq.gz in2=$output/$sample/${sample}.trimmed2.fq.gz out=$output/$sample/${sample}.merged.fq.gz outu1=$output/$sample/${sample}.1_un.fq.gz outu2=$output/$sample/${sample}.2_un.fq.gz

        check_exit_status "bbmerge" $?

        rm $output/$sample/${sample}.trimmed*

      fi
    ##### Map as Paired end
      if [ $do_single_end -eq "0" ]; then
        bwa mem -t $threads -M -R "@RG\tID:$sample\tSM:sample_name\tPL:illumina\tLB:lib1" ${ref} $output/$sample/${sample}.1_un.fq.gz $output/$sample/${sample}.2_un.fq.gz | samtools view -@ $threads -Sbh -q 20 -F 0x100 - > $output/$sample/${sample}.merged_un.bam

        rm $output/$sample/${sample}.1_un.fq.gz
        rm $output/$sample/${sample}.2_un.fq.gz

        bwa mem -t $threads -M -R "@RG\tID:$sample\tSM:sample_name\tPL:illumina\tLB:lib1" ${ref} $output/$sample/${sample}.merged.fq.gz | samtools view -@ $threads -Sbh -q 20 -F 0x100 - > $output/$sample/${sample}.merged.bam

        check_exit_status "bwa_mem" $?

        rm $output/$sample/${sample}.merged.fq.gz

        java -jar $PICARD MergeSamFiles I=$output/$sample/${sample}.merged.bam I=$output/$sample/${sample}.merged_un.bam SO=coordinate USE_THREADING=true O=$output/$sample/${sample}.sorted_merged.bam
        check_exit_status "Picard_MergeSamFiles" $?

        echo "Mapped as PE done!"
      fi

    ### Begin Mapping as Single end
      if [ $do_single_end -eq "1" ]; then
        bwa mem -t $threads -M -R "@RG\tID:$sample\tSM:sample_name\tPL:illumina\tLB:lib1" ${ref} $output/$sample/${sample}.trimmed1.fq.gz | samtools view -@ $threads -Sbh -q 20 -F 0x100 - > $output/$sample/${sample}.merged.bam

        java -jar $PICARD SortSam \
       	I=$output/$sample/${sample}.merged.bam \
       	O=$output/$sample/${sample}.sorted_merged.bam \
       	SO=coordinate \
       	VALIDATION_STRINGENCY=SILENT

        rm $output/$sample/${sample}.trimmed*
        echo "Mapped as SE done!"
      fi

    ### Continue with Picard and remove duplication
      rm $output/$sample/${sample}.merged.bam
      rm $output/$sample/${sample}.merged_un.bam

      java -jar $PICARD MarkDuplicates \
      REMOVE_DUPLICATES=true \
      I=$output/$sample/${sample}.sorted_merged.bam \
      O=$output/$sample/${sample}.dedup.bam \
      M=$output/$sample/${sample}.mark_duplicates_report.txt \
      VALIDATION_STRINGENCY=SILENT

      check_exit_status "Picard_MarkDuplicates" $?

      rm $output/$sample/${sample}.sorted_merged.bam

      samtools index $output/$sample/${sample}.dedup.bam

      java -jar $GATK -T RealignerTargetCreator \
      -nt $threads \
      -R ${ref} \
      -I $output/$sample/${sample}.dedup.bam \
      -o $output/$sample/${sample}.hologenome.intervals

      check_exit_status "GATK_RealignerTargetCreator" $?

      java -jar $GATK \
      -T IndelRealigner \
      -R ${ref} \
      -I $output/$sample/${sample}.dedup.bam \
      -targetIntervals $output/$sample/${sample}.hologenome.intervals \
      -o $output/$sample/${sample}.contaminated_realigned.bam

      check_exit_status "GATK_IndelRealigner" $?

      rm $output/$sample/${sample}.dedup.bam*

    ### output and format bam files focusing on specific genomes; make pileup
      while read p; do
           #prefix=mel
           prefix=$( echo $p | cut -f1 -d',')
           echo $prefix
           chrs=$( echo $p | cut -f2 -d',')
           echo $chrs
           refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )

           samtools view -@ $threads $output/$sample/${sample}.contaminated_realigned.bam ${chrs} -b > $output/$sample/${sample}.${prefix}.bam

           #refOut=/scratch/aob2x/tmpRef/holo_dmel_6.12.sim.fa
           samtools sort --reference ${refOut} -@ ${threads} $output/$sample/${sample}.${prefix}.bam -o $output/$sample/${sample}.${prefix}.sort.bam
           mv $output/$sample/${sample}.${prefix}.sort.bam $output/$sample/${sample}.${prefix}.bam
           samtools index $output/$sample/${sample}.${prefix}.bam

      done < ${focalFile}

      mv $output/$sample/${sample}.contaminated_realigned.bam  $output/$sample/${sample}.original.bam
      rm $output/$sample/${sample}.contaminated_realigned.bai
      samtools index $output/$sample/${sample}.original.bam
  fi

#################
### do pileup ###
#################

  #output=/scratch/aob2x/dest_v3_output/
  #sample=DE_Bad_Bro_1_2020-07-16
  #prefix=sim
  #chrs="sim_2L sim_2R sim_3L sim_3R sim_4 sim_mtDNA sim_X"
  #nflies=40
  #ref=/scratch/aob2x/tmpRef/holo_dmel_6.12.fa
  #focalfile=/scratch/aob2x/tmpRef/focalFile.csv
  #base_quality_threshold=25

  if [ $do_pileup -eq "1"]; then
    echo "Doing Pileup"
    doPILEUP_function () {

       prefix=$( echo $1 | cut -f1 -d',')
       chr=$( echo $1 | cut -f2 -d',')
       # prefix=sim; chr=sim_2L
       refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )

       #echo ${1}
       echo ${refOut}
       samtools view -O BAM ${output}/${sample}/${sample}.${prefix}.bam ${chr} | \
       samtools mpileup -  \
       -B \
       -Q ${base_quality_threshold} \
       -f ${refOut}  > ${output}/${sample}/${sample}.${prefix}.${chr}.mpileup.txt
    }
    export -f doPILEUP_function
    export output sample sample base_quality_threshold ref

    parallel -j ${threads} doPILEUP_function ::: $( cat $focalfile | awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )
  fi

###################
### do pool_snp ###
###################
  if [ $do_poolsnp -eq "1" ]; then
    doPOOLSNP_function () {
      prefix=$( echo $1 | cut -f1 -d',')
      chr=$( echo $1 | cut -f2 -d',')
      # prefix=sim; chr=sim_2L
      refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )

      python3 /opt/DESTv3/mappingPipeline/scripts/Mpileup2Sync.py \
      --mpileup $output/$sample/${sample}.${prefix}.${chr}.mpileup.txt \
      --ref ${refOut}.ref \
      --output $output/$sample/${sample}.${prefix}.${chr}_chr \
      --base-quality-threshold $base_quality_threshold \
      --coding $illumina_quality_coding \
      --minIndel $minIndel

      check_exit_status "Mpileup2Sync" $?

      #For the PoolSNP output
      python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_complete.py \
      --sync $output/$sample/${sample}.${prefix}.${chr}_chr.sync.gz \
      --output $output/$sample/${sample}.${prefix}.${chr}_chr \
      --indel $output/$sample/${sample}.${prefix}.indel \
      --coverage $output/$sample/${sample}.${prefix}.cov \
      --mincov $min_cov \
      --maxcov $max_cov \
      --maxsnape $maxsnape

      check_exit_status "MaskSYNC" $?

      gunzip $output/$sample/${sample}.${prefix}.${chr}_chr.masked.sync.gz
      gunzip $output/$sample/${sample}.${prefix}.${chr}_chr.sync.gz

    }
    export -f doPOOLSNP_function
    export output sample sample base_quality_threshold ref min_cov max_cov maxsnape illumina_quality_coding
    parallel -j ${threads} doPOOLSNP_function ::: $( cat $focalfile | awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )

    ### collect
    collectPOOLSNP_function () {

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.sync |
        bgzip -c > ${output}/${sample}/${sample}.${prefix}.sync.gz
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.masked.sync.gz

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.masked.sync |
        bgzip -c > ${output}/${sample}/${sample}.${prefix}.masked.sync.gz
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.masked.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.masked.sync.gz

    }
    export -f collectPOOLSNP_function
    parallel -j ${threads} collectPOOLSNP_function ::: $( cat $focalfile | cut -f1 -d',' )

    #rm $output/$sample/${sample}.${prefix}_mpileup.txt

    echo "Read 1: $read1" >> $output/$sample/${sample}.parameters.txt
    echo "Read 2: $read2" >> $output/$sample/${sample}.parameters.txt
    echo "Sample name: $sample" >> $output/$sample/${sample}.parameters.txt
    echo "Output directory: $output" >> $output/$sample/${sample}.parameters.txt
    echo "Number of cores used: $threads" >> $output/$sample/${sample}.parameters.txt
    echo "Max cov: $max_cov" >> $output/$sample/${sample}.parameters.txt
    echo "Min cov $min_cov" >> $output/$sample/${sample}.parameters.txt
    echo "base-quality-threshold $base_quality_threshold" >> $output/$sample/${sample}.parameters.txt
    echo "illumina-quality-coding $illumina_quality_coding" >> $output/$sample/${sample}.parameters.txt
    echo "min-indel $minIndel" >> $output/$sample/${sample}.parameters.txt
    echo "species prefix ${prefix}" >> $output/$sample/${sample}.parameters.txt
  fi

################
### do SNAPE ###
################
  if [ $do_snape -eq "1" ]; then
    while read p; do
      prefix=$( echo $p | cut -f1 -d',')
      echo $prefix
      chrs=$( echo $p | cut -f2 -d',')
      echo $chrs
      refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )

      ### infer sex ratio
        #output=/scratch/aob2x/dest_v3_output/
        #sample=DE_Bad_Bro_1_2020-07-16
        #prefix=mel
        #chrs="2L 2R 3L 3R 4 mtDNA X"
        #nflies=40

        #output=/scratch/aob2x/dest_v3_output/
        #sample=DE_Bad_Bro_1_2020-07-16
        #prefix=sim
        #chrs="sim_2L sim_2R sim_3L sim_3R sim_4 sim_mtDNA sim_X"
        #nflies=40

        nXchr=$( samtools idxstats ${output}/${sample}/${sample}.${prefix}.bam  | grep -E $( echo "$chrs" | sed 's/ /|/g' ) | awk -v nFlies=${nflies} '
          BEGIN {
            autLen=0
            sexLen=0
            autRD=0
            sexRD=0
          }
          {
            if($3>0) {
              if(!match($0, /X/) && !match($0, /Y/) && !match($0, /mtDNA/) && !match($0, /mitochondrion_genome/)) {
                autLen+=$2
                autRD+=$3
              }
              if(match($0, /X/)) {
                sexLen+=$2
                sexRD+=$3
              }
            }
          }
          END {
            print "autCov: "autRD/autLen  > "/dev/stderr"
            print "sexCov: "sexRD/sexLen  > "/dev/stderr"
            print "SR: " (autRD/autLen)/(sexRD/sexLen)  > "/dev/stderr"
            propFemale=(2-(autRD/autLen)/(sexRD/sexLen))/((autRD/autLen)/(sexRD/sexLen))
            print "prop Female: " propFemale  > "/dev/stderr"
            print "nFemales: " propFemale*nFlies  > "/dev/stderr"
            print "nMales: " (1-propFemale)*nFlies  > "/dev/stderr"
            print int(2*propFemale*nFlies  + (1-propFemale)*nFlies + .5)
          }
          ')
        echo "number of estimated X-chromosomes" $nXchr

      ### split the mpileup on chromosome
        cd $output/$sample
        awk -v prefix=${prefix} -v sample=${sample} '{if (last != $1) close(last); print >> sample"."prefix"."$1; last = sample"."prefix"."$1}' ${output}/${sample}/${sample}.${prefix}_mpileup.txt

      ### run SNAPE function
        export nflies theta D priortype fold chr sample output nXchr refOut prefix

        doSNAPE_function () {
          chr=$1
          # chr="sim_2L"

          if [[ "$chr" != *"_X"* && "$chr" != *"_Y"* && "$chr" != *"_mtDNA"* ]]; then
            nChr=$((${nflies}*2))
          else
            nChr=nXchr
          fi

          snape-pooled -nchr ${nChr} -theta $theta -D $D -priortype $priortype -fold $fold < ${output}/${sample}/${sample}.${prefix}.${chr} > ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.txt

          gzip -f ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.output.txt

          python3 /opt/DESTv3/mappingPipeline/scripts/SNAPE2SYNC.py \
          --input ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.output.txt.gz \
          --ref ${refOut} \
          --output ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE

          check_exit_status "SNAPE2SYNC" $?

          python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_complete.py \
          --sync   ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.sync.gz \
          --output ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.complete \
          --indel     ${output}/${sample}/${sample}.indel \
          --coverage  ${output}/${sample}/${sample}.cov \
          --mincov $min_cov \
          --maxcov $max_cov \
          --maxsnape $maxsnape \
          --SNAPE

          check_exit_status "MaskSYNC_SNAPE_Complete" $?

          mv ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.complete_masked.sync.gz ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.complete.masked.sync.gz

          python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_monomorphic_filter.py \
          --sync ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.complete.masked.sync.gz \
          --output ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.monomorphic \
          --indel $output/$sample/${sample}.indel \
          --coverage $output/$sample/${sample}.cov \
          --mincov $min_cov \
          --maxcov $max_cov \
          --maxsnape $maxsnape \
          --SNAPE

          check_exit_status "MaskSYNC_SNAPE_Monomporphic_Filter" $?

          mv ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.monomorphic_masked.sync.gz ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.monomorphic.masked.sync.gz

          gunzip ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.complete.masked.sync.gz
          gunzip ${output}/${sample}/${sample}.${prefix}.${chr}.SNAPE.monomorphic.masked.sync.gz

        }
        export -f doSNAPE_function

      ### figure out parallel call
        parallel -j ${threads} doSNAPE_function ::: $( cat /scratch/aob2x/tmpRef/focalFile.csv | head -n1 | cut -f2 -d',' )

      ### collect
        cat ${output}/${sample}/${sample}.${prefix}.*.SNAPE.complete.masked.sync.gz > ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync
        cat ${output}/${sample}/${sample}.${prefix}.*.SNAPE.monomorphic.masked.sync.gz > ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync

        bgzip ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync.gz

        bgzip ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync.gz

        check_exit_status "tabix" $?

        #gzip $output/$sample/${sample}.mel_mpileup.txt

        echo "Maxsnape $maxsnape" >> $output/$sample/${sample}.parameters.txt
        echo "theta:  $theta" >> $output/$sample/${sample}.parameters.txt
        echo "D:  $D" >> $output/$sample/${sample}.parameters.txt
        echo "priortype: $priortype" >> $output/$sample/${sample}.parameters.txt
        echo "species prefix ${prefix}" >> $output/$sample/${sample}.parameters.txt

    done < ${focalFile}
  fi

###########
### Bye ###
###########
  echo "Completed: "${date}
