


# First fetch the saved images using the TOWN, FRAMERATE and IT variables
TOWN=$1
FRAMERATE=$2
IT=$3
FPSSTEP=60
FDIR=/home/wklingel/carla_release/_benchmark_results/TOWN${TOWN}/1800s_200p0v/${FRAMERATE}/
BASEDIR=${FDIR}imgs/it${IT}/
DARKNETDIR=/home/wklingel/darknet-mine/


# If time-based frame rate, change the FPSSTEP variable
if [[ $FRAMERATE == *"fps" ]]; then
    FPSSTEP=${FRAMERATE:0:2}
fi
if [ ! -d $BASEDIR ]; then
    echo "No such images saved!"
    exit 1
fi
# Create a file containing the names of the images
if [ ! -f ${BASEDIR}/imagepaths.txt ]; then
    echo File with frame numbers does not exist yet
    ls ${BASEDIR} | grep png | sed -r 's/^.+\///' | sed "s/^[0-9]*_\([0-9]*\).*$/\1/g" | sed "s/.png$//g" > ${BASEDIR}imagepaths.txt
fi
# Create a movie from all the images created in the CARLA simulator
if [ ! -f ${BASEDIR}/movie.mp4 ]; then
    echo Movie does not exist yet
    ffmpeg -r 60 -f image2 -pattern_type glob -i "${BASEDIR}*.png" ${BASEDIR}movie.mp4
    echo "Movie created, experiment ended to eliminate movie creation power consumption"
    exit 1
fi

echo ${FPSSTEP}
cd ${DARKNETDIR}
# Execute the object detection algorithm
./darknet detector demo cfg/coco.data cfg/yolov3.cfg yolov3.weights -dont_show ${BASEDIR}movie.mp4 -wait_frames ${BASEDIR}imagepaths.txt -fps_step ${FPSSTEP} &
PROC_ID=$!
echo $PROC_ID
SUM=0
ITS=0
# Iterate as long as the object detection is running
while kill -0 "$PROC_ID" >/dev/null 2>&1; do
    # Fetch the current power draw and add it to the SUM variable
    SUM=$(echo "$SUM+$(nvidia-smi --format=csv,noheader,nounits --query-gpu=power.draw)" | bc -l)
    ((ITS+=1))
    sleep 1
    echo $ITS
done
echo "PROCESS TERMINATED"
echo "Total Consumed Energy: $SUM J"
# Calculate the average consumed power
AVG_POWER=$(echo "$SUM/$ITS" | bc -l)
echo "Average Power Consumed: $AVG_POWER W"

COLUMN_NAMES="ItNr;AvgPower(W);TotalEnergy(J)"
if [ ! -f ${FDIR}power_results.csv ]; then
        echo ${COLUMN_NAMES} >> ${FDIR}power_results.csv
fi

echo "$3;$AVG_POWER;$SUM" >> ${FDIR}power_results.csv

exit 0
