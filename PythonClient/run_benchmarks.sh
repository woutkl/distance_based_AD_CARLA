#!/usr/bin/env bash

#fpm_options=(2.4 2.2 2.0 1.8 1.6 1.4 1.2 1.0 0.8 0.6)
fpm_options=(2.0 1.8 1.6 1.4 1.2 1.0)
ITERS=$1
SCNDS=$2
TOWN=TOWN2
APPEND=false
APPEND=$3
PEDESTRIANS=$4
VEHICLES=$5


BASEDIR=../_benchmark_results/${TOWN}/${SCNDS}s_${PEDESTRIANS}p${VEHICLES}v

# Check if the directory exists, if not create one
if [ ! -d $BASEDIR ]; then
    mkdir $BASEDIR
fi

# Check if this experiment is already done, if so then exit this script
for fpm in ${fpm_options[@]}
do
    if [ -d ${BASEDIR}/${fpm}fpm ]; then
        if [ "$APPEND" = false ]; then
            echo "ERROR: one of the experiments is already done, can not override!"
            exit 1
        fi
    fi
done


COLUMN_NAMES="Collision damage;Offroad metric;Other lane metric;Total game time;Total travelled distance;Number of frames using FPS;Number of frames using FPM (+1second updates)"

for fpm in ${fpm_options[@]}
do
    echo Frames Per Meter: $fpm
    mkdir $BASEDIR/${fpm}fpm $BASEDIR/${fpm}fpm/imgs
    if [ ! -f ${BASEDIR}/${fpm}fpm/results.csv ]; then
        echo ${COLUMN_NAMES} >> ${BASEDIR}/${fpm}fpm/results.csv
    fi
    start=1
    if [ "$APPEND" = true  ]; then
        start=`cat $BASEDIR/${fpm}fpm/results.csv | wc -l`
    fi
    echo $start
    for i in $(seq ${start} $ITERS) 
    do
        echo Iteration $i
        PATHITER=$BASEDIR/${fpm}fpm/imgs/it${i}
        python3 distance_based_autopilot.py -i -q Low --fpm ${fpm} -s ${SCNDS} --savepath ${PATHITER} -p 200 -v 0
    done
done
