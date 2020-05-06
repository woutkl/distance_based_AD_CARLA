



TOWN=$1
FRAMERATE=$2
IT=$3
FPSSTEP=60
FDIR=/home/wklingel/carla_release/_benchmark_results/TOWN${TOWN}/1800s_200p0v/${FRAMERATE}/
BASEDIR=${FDIR}imgs/it${IT}/
DARKNETDIR=/home/wklingel/darknet-mine/


if [[ $FRAMERATE == *"fps" ]]; then
    FPSSTEP=${FRAMERATE:0:2}
fi
if [ ! -d $BASEDIR ]; then
    echo "No such images saved!"
    exit 1
fi
if [ ! -f ${BASEDIR}/imagepaths.txt ]; then
    echo File with frame numbers does not exist yet
    ls ${BASEDIR} | grep png | sed -r 's/^.+\///' | sed "s/^[0-9]*_\([0-9]*\).*$/\1/g" | sed "s/.png$//g" > ${BASEDIR}imagepaths.txt
fi
if [ ! -f ${BASEDIR}/movie.mp4 ]; then
    echo Movie does not exist yet
    ffmpeg -r 60 -f image2 -pattern_type glob -i "${BASEDIR}*.png" ${BASEDIR}movie.mp4
    echo "Movie created, experiment ended to eliminate movie creation power consumption"
    exit 1
fi

echo ${FPSSTEP}
cd ${DARKNETDIR}
./darknet detector demo cfg/coco.data cfg/yolov3.cfg yolov3.weights -dont_show ${BASEDIR}movie.mp4 -wait_frames ${BASEDIR}imagepaths.txt -fps_step ${FPSSTEP} &
PROC_ID=$!
echo $PROC_ID
SUM=0
ITS=0
while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    SUM=$(echo "$SUM+$(nvidia-smi --format=csv,noheader,nounits --query-gpu=power.draw)" | bc -l)
    ((ITS+=1))
    sleep 1
    echo $ITS
done
echo "PROCESS TERMINATED"
echo "Total Consumed Energy: $SUM J"
AVG_POWER=$(echo "$SUM/$ITS" | bc -l)
echo "Average Power Consumed: $AVG_POWER W"

COLUMN_NAMES="ItNr;AvgPower(W);TotalEnergy(J)"
if [ ! -f ${FDIR}power_results.csv ]; then
        echo ${COLUMN_NAMES} >> ${FDIR}power_results.csv
fi

echo "$3;$AVG_POWER;$SUM" >> ${FDIR}power_results.csv

exit 0
