#!/usr/bin/env bash

ITERS=$1
SCNDS=$2
TOWN=TOWN$7
fps=30
APPEND=false
APPEND=$3
PEDESTRIANS=$4
VEHICLES=$5
PORT=2000
PORT=$6


BASEDIR=../_benchmark_results/${TOWN}/${SCNDS}s_${PEDESTRIANS}p${VEHICLES}v

# Check if the directory exists, if not create one
if [ ! -d $BASEDIR ]; then
    mkdir $BASEDIR
fi

# Check if this experiment is already done, if so then exit this script
if [ -d ${BASEDIR}/${fps}fps ]; then
    if [ "$APPEND" = false  ]; then
        echo "ERROR: one of the experiments is already done, can not override!"
        exit 1
    fi
fi


COLUMN_NAMES="Collision damage;Offroad metric;Other lane metric;Total game time;Total travelled distance;Number of frames using FPS"

echo Frames Per Second: $fps
mkdir $BASEDIR/${fps}fps $BASEDIR/${fps}fps/imgs
if [ ! -f ${BASEDIR}/${fps}fps/results.csv ]; then
    echo ${COLUMN_NAMES} >> ${BASEDIR}/${fps}fps/results.csv
fi
start=1
if [ "$APPEND" = true  ]; then
    start=`cat $BASEDIR/${fps}fps/results.csv | wc -l`
fi
echo $start
for i in $(seq ${start} $ITERS) 
do
    echo Iteration $i
    PATHITER=$BASEDIR/${fps}fps/imgs/it${i}
    python3 time_based_autopilot.py -q Low -s ${SCNDS} --fps ${fps} --savepath ${PATHITER} -p 200 -v 0 --port ${PORT}
done

