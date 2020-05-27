
# The town for which to fetch the created images from the CARLA simulator during the performance experiments.
TOWN=2


# The frame rate configurations for which to fetch the images.
#fpm_options=(0.4fpm 0.6fpm 0.8fpm 1.0fpm 1.2fpm 1.4fpm 1.6fpm 1.8fpm 2.0fpm 2.2fpm 2.4fpm 10fps 30fps 45fps)
fpm_options=(1.8fpm 10fps 30fps 45fps)

# Iterate over the different frame rates
for fpm in ${fpm_options[@]}
do
    echo $fpm
    # Execute the power experiment for each frame rate 5 times
    for IT in 1 2 3 4 5; do
        echo $IT
        # Execute the power experiment
        ./power_experiments.sh $TOWN $fpm $IT
        # Sleep for 20 seconds to make sure that the dynamic power consumption is reduced again.
        sleep 20 
    done
done


exit 1


