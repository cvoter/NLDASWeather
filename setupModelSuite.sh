#!/bin/bash
# setupModelSuite.sh
# 2018.04 Carolyn Voter
# Loops through runnames as specified to create dagfiles and spliced dagfiles.
# Usage: sh setupModelSuite.sh

# ==============================================================================
# SET PARAMETERS
# ==============================================================================
nruns=$(((nHr+ndrun-1)/ndrun))
modelsuite=Weather
splicefile=/home/cvoter/NLDASWeather/modelsplice/$modelsuite.dag

# ==============================================================================
# DEFINE FUNCTIONS
# ==============================================================================
createModelDir () {
    # Copy template
    cd /home/cvoter/NLDASWeather
    cp -r modelname $locname

    #Replace modelname w/real runname
    cd $locname
    sed "s/ilocname/$locname/g" modelname.dag > tmpfile; mv tmpfile modelname.dag
    sed "s/iloc/$loc/g" modelname.dag > tmpfile; mv tmpfile $locname.dag

    #Remove modelname
    rm modelname.dag
}

# ==============================================================================
# LOOP OVER MODELS
# ==============================================================================
for ((loc=1;loc<=51;loc++)); do
  locname=$(printf "loc%02d" $loc)
  dagname=$(printf "D%02d" $loc)
  echo $locname

  #Create dag and add to spliced dag file
  createModelDir
  printf "SPLICE %s /home/cvoter/NLDASWeather/%s/%s.dag\n" $dagname $locname $locname >> $splicefile
done