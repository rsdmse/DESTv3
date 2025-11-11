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
  do_cleanup=0
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
      -dps|--do_poolsnp)
      do_poolsnp=$2
      shift # past argument
      shift # past value
      ;;
      -ds|--do_snape)
      do_snape=$2
      shift # past argument
      shift # past value
      ;;
      -dopileup|--do_pileup)
      do_pileup=$2
      shift # past argument
      shift # past value
      ;;
      -docleanup|--do_cleanup)
      do_cleanup=$2
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

  echo -e "This is DEST v.3.0.0 \n Parameters as interpreted + those assumed by default --> \n"
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
  "map reads? (0 = no; 1 = yes) =" $do_map "\n" \
  "do pileup? (0 = no; 1 = yes) =" $do_pileup "\n" \
  "do snape? (0 = no; 1 = yes) =" $do_snape "\n" \
  "do poolsnp? (0 = no; 1 = yes) =" $do_poolsnp "\n" \
  "do cleanup? (0 = no; 1 = yes) =" $do_cleanup "\n" \
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

      makePickles () {
        # ref=/scratch/aob2x/tmpRef/holo_dmel_6.12.fa; prefix=mel; chrs=2L
        prefix=$( echo $1 | cut -f1 -d',')
        echo $prefix
        chrs=$( echo $1 | cut -f2 -d',')
        echo $chrs

        picklesDir=$( echo $ref | awk -F'/' '{ for(i=1; i<NF; i++) printf $i"/"; printf "pickles"}' )
        if [ ! -d "${picklesDir}" ]; then mkdir ${picklesDir}; fi
        refStem=$( echo $ref | awk -F'/' '{print $NF}' )
        refOut=${picklesDir}/${prefix}_${chrs}.$refStem

        echo "extracing chromosome: "$prefix $chrs
        samtools faidx ${ref} ${chrs} > ${picklesDir}/${prefix}_${chrs}.$refStem

        echo "indexing chromosome: "$prefix $chrs
        samtools faidx ${picklesDir}/${prefix}_${chrs}.$refStem

        echo "pickling chromosome: "$prefix $chrs
        python3 /opt/DESTv3/mappingPipeline/scripts/PickleRef.py \
        --ref ${picklesDir}/${prefix}_${chrs}.$refStem \
        --output ${picklesDir}/${prefix}_${chrs}.$refStem

      }
      export -f makePickles
      export ref

      parallel -j ${threads} makePickles ::: $( cat $focalFile ) ### | awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )
      exit
    fi

######################################
### do_map? Process and map reads? ###
######################################
  if [ $do_map -eq "1" ]; then
    echo "Do Map"
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
    sample=DE_Bad_Bro_1_2020-07-16
    output=/scratch/aob2x/dest_v3_output/
    threads=20
    ref=/scratch/aob2x/tmpRef/holo_dmel_6.12.fa
    focalFile=/scratch/aob2x/tmpRef/focalFile.csv

    splitBam () {
      prefix=${1}
      echo $prefix

      chrs=$( grep ${prefix} ${focalFile} | cut -f2 -d',' | tr '\n' ' ' )

      echo $chrs
      refOut=$( echo ${ref} | sed "s/fa/${prefix}.fa/g" )
      echo $refOut
      #samtools view -@ ${threads} ${output}/${sample}/${sample}.contaminated_realigned.bam ${chrs} -b > ${output}/${sample}/${sample}.${prefix}.bam
      samtools view -@ ${threads} ${output}/${sample}/${sample}.original.bam ${chrs} -b > ${output}/${sample}/${sample}.${prefix}.bam

      #refOut=/scratch/aob2x/tmpRef/holo_dmel_6.12.sim.fa
      samtools sort --reference ${refOut} -@ ${threads} ${output}/${sample}/${sample}.${prefix}.bam -o ${output}/${sample}/${sample}.${prefix}.sort.bam
      mv ${output}/${sample}/${sample}.${prefix}.sort.bam ${output}/${sample}/${sample}.${prefix}.bam
      samtools index ${output}/${sample}/${sample}.${prefix}.bam

    }
    export -f splitBam
    export focalFile ref threads output sample
    parallel -j 1 splitBam ::: $( cat ${focalFile} | cut -f1 -d',' | uniq )

    mv $output/$sample/${sample}.contaminated_realigned.bam  $output/$sample/${sample}.original.bam
    rm $output/$sample/${sample}.contaminated_realigned.bai
    samtools index $output/$sample/${sample}.original.bam
  fi

#################
### do pileup ###
#################
  if [ $do_pileup -eq "1" ]; then
    echo "Do Pileup"

    doPILEUP_function () {
       prefix=$( echo $1 | cut -f1 -d',')
       chr=$( echo $1 | cut -f2 -d',')
       # prefix=sim; chr=sim_2L

       picklesDir=$( echo $ref | awk -F'/' '{ for(i=1; i<NF; i++) printf $i"/"; printf "pickles"}' )
       if [ ! -d "${picklesDir}" ]; then mkdir ${picklesDir}; fi
       refStem=$( echo $ref | awk -F'/' '{print $NF}' )
       refOut=${picklesDir}/${prefix}_${chr}.$refStem

       echo "making pileup for " ${1}
       samtools view -b ${output}/${sample}/${sample}.${prefix}.bam ${chr} | \
       samtools mpileup -  \
       -B \
       -Q ${base_quality_threshold} \
       -f ${refOut} > ${output}/${sample}/${sample}.${prefix}.${chr}.mpileup.txt

       #check_exit_status "samtools" $?
    }
    export -f doPILEUP_function
    export output sample base_quality_threshold ref

    echo "run doPILEUP_function"
    parallel -j ${threads} doPILEUP_function ::: $( cat $focalFile ) ###| awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )
    check_exit_status "parallel" $?

  fi

###################
### do pool_snp ###
###################
  if [ $do_poolsnp -eq "1" ]; then

    ### run it
    echo "Do PoolSNP"
    doPOOLSNP_function () {
      prefix=$( echo $1 | cut -f1 -d',')
      chr=$( echo $1 | cut -f2 -d',')

      # prefix=sim; chr=sim_2L
      # output=/scratch/aob2x/dest_v3_output
      # sample=DE_Bad_Bro_1_2020-07-16
      # chr=sim_mtDNA
      # prefix=sim
      # min_cov=4
      # max_cov=.95
      # maxsnape=.9
      # ref=/scratch/aob2x/tmpRef/holo_dmel_6.12.fa
      # minIndel=5
      # illumina_quality_coding=1.8
      # base_quality_threshold=25

      picklesDir=$( echo $ref | awk -F'/' '{ for(i=1; i<NF; i++) printf $i"/"; printf "pickles"}' )
      refStem=$( echo $ref | awk -F'/' '{print $NF}' )
      refOut=${picklesDir}/${prefix}_${chr}.$refStem

      echo "Mpileup2Sync: "${prefix}" "${refOut}
      python3 /opt/DESTv3/mappingPipeline/scripts/Mpileup2Sync.py \
      --mpileup $output/$sample/${sample}.${prefix}.${chr}.mpileup.txt \
      --ref ${refOut}.ref \
      --output $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp \
      --base-quality-threshold $base_quality_threshold \
      --coding $illumina_quality_coding \
      --minIndel $minIndel

      #check_exit_status "Mpileup2Sync" $?

      #For the PoolSNP output
      echo "MaskSYNC: "${prefix}" "${refOut}

      python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_complete.py \
      --sync $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp.sync.gz \
      --output $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp \
      --indel $output/$sample/${sample}.${prefix}.${chr}_chr.indel \
      --coverage $output/$sample/${sample}.${prefix}.${chr}_chr.cov \
      --mincov $min_cov \
      --maxcov $max_cov \
      --maxsnape $maxsnape

      #check_exit_status "MaskSYNC" $?
      echo "gunzipping: "${prefix}" "${refOut}
      mv $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp_masked.sync.gz $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp.masked.sync.gz

      gunzip -f $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp.masked.sync.gz
      gunzip -f $output/$sample/${sample}.${prefix}.${chr}_chr.poolsnp.sync.gz

    }
    export -f doPOOLSNP_function
    export output sample base_quality_threshold ref min_cov max_cov maxsnape illumina_quality_coding minIndel
    #cat $focalFile
    parallel -j ${threads} doPOOLSNP_function ::: $( cat $focalFile ) ###| awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )
    check_exit_status "parallel" $?

    ### collect
    echo "collecting PoolSNP"
    collectPOOLSNP_function () {
        prefix=${1}

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.poolsnp.sync |
        bgzip -c > ${output}/${sample}/${sample}.${prefix}.poolsnp.sync.gz
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.poolsnp.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.poolsnp.sync.gz

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.poolsnp.masked.sync |
        bgzip -c > ${output}/${sample}/${sample}.${prefix}.poolsnp.masked.sync.gz
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.poolsnp.masked.sync
        tabix -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.poolsnp.masked.sync.gz

    }
    export -f collectPOOLSNP_function
    parallel -j ${threads} collectPOOLSNP_function ::: $( cat $focalFile | cut -f1 -d',' )
    check_exit_status "parallel" $?

    ### send it
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

    ### Estimate numbers for each species
    echo "Estimating species and sex ratio"
    samtools idxstats $output/$sample/${sample}.original.bam > $output/$sample/${sample}.original.bam.idxstats
    Rscript --vanilla /opt/DESTv3/mappingPipeline/scripts/species_sex_estimate.R ${focalFile} $output/$sample/${sample}.original.bam.idxstats ${nFlies}
    focalFile_idx=${output}/${sample}/${sample}.original.bam.idxstats.focalFile
    cat $focalFile_idx

    ### Run SNAPE
    echo "Do SNAPE"
    doSNAPE_function () {
      prefix=$( echo $1 | cut -f1 -d',')
      chr=$( echo $1 | cut -f2 -d',')
      nChr=$( echo $1 | cut -f4 -d',')

      ### demo
      # prefix=sim; chr=sim_mtDNA; nChr=40
      # output=/scratch/aob2x/dest_v3_output
      # sample=DE_Bad_Bro_1_2020-07-16
      # chr=sim_mtDNA
      # prefix=sim
      # min_cov=4
      # max_cov=.95
      # maxsnape=.9
      # focalFile=/scratch/aob2x/tmpRef/focalFile.csv
      # theta=0.005
      # D=0.01
      # priortype="informative"
      # fold="unfolded"
      # ref=/scratch/aob2x/tmpRef/holo_dmel_6.12.fa

      picklesDir=$( echo $ref | awk -F'/' '{ for(i=1; i<NF; i++) printf $i"/"; printf "pickles"}' )
      refStem=$( echo $ref | awk -F'/' '{print $NF}' )
      refOut=${picklesDir}/${prefix}_${chr}.$refStem
      chrs=$( cat $focalFile | grep "$prefix" | cut -f2 -d',' )

      snape-pooled -nchr ${nChr} -theta $theta -D $D -priortype $priortype -fold $fold < \
      ${output}/${sample}/${sample}.${prefix}.${chr}.mpileup.txt > \
      ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.txt

      gzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.txt

      python3 /opt/DESTv3/mappingPipeline/scripts/SNAPE2SYNC.py \
      --input ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.txt.gz \
      --ref ${refOut}.ref \
      --output ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE

      #check_exit_status "SNAPE2SYNC" $?

      python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_complete.py \
      --sync   ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.sync.gz \
      --output ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete \
      --indel     ${output}/${sample}/${sample}.${prefix}.${chr}_chr.indel \
      --coverage  ${output}/${sample}/${sample}.${prefix}.${chr}_chr.cov \
      --mincov $min_cov \
      --maxcov $max_cov \
      --maxsnape $maxsnape \
      --SNAPE

      mv ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete_masked.sync.gz \
      ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync.gz

      gunzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync.gz
      cat ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync | awk '{printf$0; if(NF==4) print "\t0:0:0:0:0:0"; if(NF==5) printf "\n" }' | \
      gzip -f -c > ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync.gz

      python3 /opt/DESTv3/mappingPipeline/scripts/MaskSYNC_snape_monomorphic_filter.py \
      --sync ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync.gz \
      --output ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.monomorphic \
      --indel $output/$sample/${sample}.${prefix}.indel \
      --coverage $output/$sample/${sample}.${prefix}.cov \
      --mincov $min_cov \
      --maxcov $max_cov \
      --maxsnape $maxsnape \
      --SNAPE

      #check_exit_status "MaskSYNC_SNAPE_Monomporphic_Filter" $?

      mv ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.monomorphic_masked.sync.gz ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.monomorphic.masked.sync.gz

      gunzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.masked.sync.gz
      gunzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.monomorphic.masked.sync.gz
      gunzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.complete.bed.gz
      gunzip -f ${output}/${sample}/${sample}.${prefix}.${chr}_chr.SNAPE.monomorphic.bed.gz
    }
    export -f doSNAPE_function
    export nflies theta D priortype fold chr sample output ref prefix min_cov max_cov maxsnape illumina_quality_coding base_quality_threshold minIndel focalFile_idx focalFile

    parallel -j ${threads} doSNAPE_function ::: $( cat $focalFile_idx ) ### | awk -F'[, ]' '{for (i=2;i<=NF;i++) {if($i!="") print $1","$i}}' )
    check_exit_status "parallel" $?

    ### collect
    echo "Collect SNAPE"
    collectSNAPE_function () {
      prefix=$( echo $1 | cut -f1 -d',')

      rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.sync.gz
      rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.txt.gz

      ### sync files
        cat ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.complete.masked.sync > \
        ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.complete.masked.sync

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.monomorphic.masked.sync > \
        ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.monomorphic.masked.sync

      ### bed files
        cat ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.complete.bed > \
        ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.bed
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.complete.bed

        cat ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.monomorphic.bed > \
        ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.bed
        rm ${output}/${sample}/${sample}.${prefix}.*_chr.SNAPE.monomorphic.bed

      ### compressing
        bgzip -f ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync
        tabix -f -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.masked.sync.gz

        bgzip -f ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync
        tabix -f -s 1 -b 2 -e 2 ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.masked.sync.gz

        bgzip -f ${output}/${sample}/${sample}.${prefix}.SNAPE.monomorphic.bed
        bgzip -f ${output}/${sample}/${sample}.${prefix}.SNAPE.complete.bed
      #check_exit_status "tabix" $?

    }
    export -f collectSNAPE_function
    parallel -j ${threads} collectSNAPE_function ::: $( cat $focalFile | cut -f1 -d',' )
    check_exit_status "parallel" $?

    ### send it
    echo "Maxsnape $maxsnape" >> $output/$sample/${sample}.parameters.txt
    echo "theta:  $theta" >> $output/$sample/${sample}.parameters.txt
    echo "D:  $D" >> $output/$sample/${sample}.parameters.txt
    echo "priortype: $priortype" >> $output/$sample/${sample}.parameters.txt
    echo "species prefix ${prefix}" >> $output/$sample/${sample}.parameters.txt
  fi

###############
### Cleanup ###
###############
  if [ $do_cleanup -eq "1" ]; then
    cleanupPileup () {
      prefix=${1}

      tar czvf ${output}/${sample}/${sample}.${prefix}.mpileup.tar.gz ${output}/${sample}/${sample}.${prefix}*.mpileup.txt
      rm ${output}/${sample}/${sample}.${prefix}*.mpileup.txt

    }
    export -f cleanupPileup
    export sample output
    parallel ::: $( cat $focalFile | cut -f1 -d',' )

  fi

###########
### Bye ###
###########
  echo "Completed: " $( date "+%Y-%m-%d %H:%M:%S" )
