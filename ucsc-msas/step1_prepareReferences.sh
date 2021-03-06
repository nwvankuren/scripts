#!/bin/bash

#PBS -d .
#PBS -l mem=8gb,nodes=1:ppn=16,walltime=96:00:00
#PBS -e error/${F}.step1.err
#PBS -o output/${F}.step1.out

. ~/.bashrc
module load repeatmasker
module load python/2.7.13
module load UCSCtools

##execute from project directory

R="genomes/${F}_allfiles/${F}"

##Remove short scaffolds
perl scripts/step1a_removeShortScaffolds.pl ${R}.fa 5000 ${R}.gt5kb.fa

##RepeatMasker
if [ "$M" -eq "1" ]; then
    
    RepeatMasker -species arthropods -xsmall -pa 16 ${R}.gt5kb.fa
    mkdir genomes/${F}_allfiles/rmask_files
    mv ${R}.gt5kb.fa.cat ${R}.gt5kb.fa.out ${R}.gt5kb.fa.tbl genomes/${F}_allfiles/rmask_files

else
    cp ${R}.gt5kb.fa ${R}.gt5kb.fa.masked
fi

##format sequences
mkdir ${R}	
faSplit byName ${R}.gt5kb.fa.masked $R/

##remove sequences with < 100 informative (non-N, non-masked) sites
##from the fasta directory

perl scripts/step1b_deleteMaskedFastas.pl $F ${R}/

##prepare necessary files for lastz, conversion of lav to psl

cat ${R}/*.fa > ${R}.rm.fa
faToTwoBit ${R}.rm.fa ${R}.2bit
twoBitInfo ${R}.2bit stdout | sort -k2nr > ${R}.info

##Create a lift file
perl scripts/step1c_partitionSequence.pl 50000000 0 ${R}.2bit ${R}.info 1 -lstDir ${R}_lst > /dev/null
cat ${R}_lst/* > ${R}.parts.list
perl scripts/step1d_constructLiftFile.pl ${R}.info ${R}.parts.list > ${R}.lift

mkdir ${R}_2bit
	
for j in `ls ${R}/ | grep ".fa$"`
    do
        faToTwoBit ${R}/${j} ${R}_2bit/`echo $j | sed 's/\.fa//'`.2bit
done




