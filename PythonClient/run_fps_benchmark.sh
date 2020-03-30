#!/usr/bin/env bash

ITERS=$1
SCNDS=$2
TOWN=TOWN2
fps=60
BASEDIR=_benchmark_results/${TOWN}/${SCNDS}s

# Check if the directory exists, if not create one
if [ ! -d $BASEDIR ]; then
    mkdir $BASEDIR
fi

# Check if this experiment is already done, if so then exit this script
if [ -d ${BASEDIR}/${fps}fps ]; then
    echo "ERROR: one of the experiments is already done, can not override!"
    exit 1
fi


COLUMN_NAMES="Collision damage;Offroad metric;Other lane metric;Total game time;Total travelled distance;Number of frames using FPS"

echo Frames Per Second: $fps
mkdir $BASEDIR/${fps}fps $BASEDIR/${fps}fps/imgs
echo ${COLUMN_NAMES} >> ${BASEDIR}/${fps}fps/results.csv
for i in $(seq 1 $ITERS) 
do
    echo Iteration $i
    PATHITER=$BASEDIR/${fps}fps/imgs/it${i}
    python3 time_based_autopilot.py -i -q Low -s ${SCNDS} --savepath ${PATHITER}
done

