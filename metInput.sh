#!/bin/bash
#
# Carolyn Voter
# 2016.09.13; major update 2016.09.28
# This file manages generation of the met forcing *.txt file for parflow
# File and dir paths based CHTC organization
#
# Recall format of batch.get_nldas is:
# "/path/to/grb/dir/"
# "name.of.output.file.txt"
# decimal.lat decimal.long
# 1980 10 01 00
# 2010 09 30 23

# GET INPUT ARGUMENTS
export locname=$1
export loc=$2
export start=$3
export end=$4
export filename=$5
export njob=$6

# ESTABLISH DIRECTORIES
grbDir=/mnt/gluster/cvoter/WY1981_WY2016
outDir=/mnt/gluster/cvoter/Spinup_in/$locname
#move to new location
if [ ! -e $outDir ]; then
  mkdir $outDir
  mkdir $outDir/logs
fi

# REPLACE LINES THAT ARE SAME FOR ALL LOOPS
#replace 1st line with correct grbDir
sed -i "1s|.*|$grbDir|" batch.get_nldas
sed -i '1s|.*|\"&\"|' batch.get_nldas

#replace 2nd line with standard filename
sed -i "2s|.*|$filename|" batch.get_nldas
sed -i '2s|.*|\"&\"|' batch.get_nldas

#replace 3rd line with correct lat long
latlong=$(sed -n "${loc}p" locations.txt)
sed -i "3s|.*|$latlong|" batch.get_nldas

#replace 4th line with correct start year
sed -i "4s|.*|$start|" batch.get_nldas

#replace 5th line with correct end year
sed -i "5s|.*|$end|" batch.get_nldas

#execute *.f90 file
./get_nldas.1D &>> NLDAS.$loc.$njob.out

#move key files back to gluster
mv $filename $outDir/$filename
mv batch.get_nldas $outDir/logs/batch.$loc.$njob.get_nldas
mv NLDAS.$loc.$njob.out $outDir/logs/
rm *

#for spinups, now copy all other input files into gluster folder
#cp /mnt/gluster/cvoter/ParflowOut/Spinup_in/allLoc/* $outDir/