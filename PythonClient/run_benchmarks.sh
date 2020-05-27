#!/usr/bin/env bash

# The fpm frame rate configurations for which to run experiments
#fpm_options=(2.4 2.2 2.0 1.8 1.6 1.4 1.2 1.0 0.8 0.6)
fpm_options=(2.2 2.4)
# How many experiments should be executed per frame rate configuration
ITERS=$1
# The maximum time of a simulation experiment
SCNDS=$2
# Which built-in town to use
TOWN=TOWN$7
APPEND=false
# Whether to append the results to an existing file
APPEND=$3
# The number of pedestrians to use in the simulator
PEDESTRIANS=$4
# The number of vehicles to use in the simulator
VEHICLES=$5
PORT=2000
# At which port the client should connect to the server
PORT=$6

BASEDIR=../_benchmark_results/${TOWN}/${SCNDS}s_${PEDESTRIANS}p${VEHICLES}v

# Check if the directory exists, if not create one
if [ ! -d $BASEDIR ]; then
    mkdir $BASEDIR
fi

# Check if this experiment is already done and if it should not append to an existing file, if so then exit this script
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

# Iterate over the different frame rates
for fpm in ${fpm_options[@]}
do
    echo Frames Per Meter: $fpm
    # Create the necessary result files
    mkdir $BASEDIR/${fpm}fpm $BASEDIR/${fpm}fpm/imgs
    if [ ! -f ${BASEDIR}/${fpm}fpm/results.csv ]; then
        echo ${COLUMN_NAMES} >> ${BASEDIR}/${fpm}fpm/results.csv
    fi
    start=1
    if [ "$APPEND" = true  ]; then
        # Calculate the number of experiments already executed for this frame rate configuration
        start=`cat $BASEDIR/${fpm}fpm/results.csv | wc -l`
    fi
    echo $start
    # Iterate of the number of experiments to execute
    for i in $(seq ${start} $ITERS) 
    do
        echo Iteration $i
        PATHITER=$BASEDIR/${fpm}fpm/imgs/it${i}
        # Execute the experiment in the CARLA simulator
        python3 distance_based_autopilot.py -q Low --fpm ${fpm} -s ${SCNDS} --savepath ${PATHITER} -p 200 -v 0 --port ${PORT}
    done
done
