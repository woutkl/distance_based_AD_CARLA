#!/usr/bin/env bash

# How many experiments should be executed per frame rate configuration
ITERS=$1
# The maximum time of a simulation experiment
SCNDS=$2
# Which built-in town to use
TOWN=TOWN$7
# The fps frame rate to use for the time-based experiments
fps=30
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
if [ -d ${BASEDIR}/${fps}fps ]; then
    if [ "$APPEND" = false  ]; then
        echo "ERROR: one of the experiments is already done, can not override!"
        exit 1
    fi
fi


COLUMN_NAMES="Collision damage;Offroad metric;Other lane metric;Total game time;Total travelled distance;Number of frames using FPS"

echo Frames Per Second: $fps
# Create the experiment files
mkdir $BASEDIR/${fps}fps $BASEDIR/${fps}fps/imgs
if [ ! -f ${BASEDIR}/${fps}fps/results.csv ]; then
    echo ${COLUMN_NAMES} >> ${BASEDIR}/${fps}fps/results.csv
fi
start=1
if [ "$APPEND" = true  ]; then
    # Get the number of already executed experiments for this frame rate
    start=`cat $BASEDIR/${fps}fps/results.csv | wc -l`
fi
echo $start
# Iterate over the number of executions
for i in $(seq ${start} $ITERS) 
do
    echo Iteration $i
    PATHITER=$BASEDIR/${fps}fps/imgs/it${i}
    # Execute the simulation in the CARLA simulator
    python3 time_based_autopilot.py -q Low -s ${SCNDS} --fps ${fps} --savepath ${PATHITER} -p 200 -v 0 --port ${PORT}
done

