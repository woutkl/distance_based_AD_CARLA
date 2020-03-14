#!/usr/bin/env python3

# Copyright (c) 2017 Computer Vision Center (CVC) at the Universitat Autonoma de
# Barcelona (UAB).
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

import argparse
import logging
import random
import time
import numpy as np


from carla.client import make_carla_client
from carla.sensor import Camera
from carla.settings import CarlaSettings
from carla.tcp import TCPConnectionError
from carla.util import print_over_same_line



def run_carla_client(args):
    # Here we will run 3 episodes with 300 frames each.
    number_of_episodes = 3
    frames_per_episode = 500
    # Number of frames to be processed per meter
    fpm = 2

    # We assume the CARLA server is already waiting for a client to connect at
    # host:port. To create a connection we can use the `make_carla_client`
    # context manager, it creates a CARLA client object and starts the
    # connection. It will throw an exception if something goes wrong. The
    # context manager makes sure the connection is always cleaned up on exit.
    with make_carla_client(args.host, args.port) as client:
        print('CarlaClient connected')

        for episode in range(0, number_of_episodes):
            # Start a new episode.

            # Initialize environment settings
            if args.settings_filepath is None:
                # Create the carla settings programmatically
                settings = make_carla_settings(args)
            else:
                # Alternatively, we can load these settings from a file.
                with open(args.settings_filepath, 'r') as fp:
                    settings = fp.read()

            # Now we load these settings into the server. The server replies
            # with a scene description containing the available start spots for
            # the player. Here we can provide a CarlaSettings object or a
            # CarlaSettings.ini file as string.
            scene = client.load_settings(settings)

            # Choose one player start at random.
            number_of_player_starts = len(scene.player_start_spots)
            player_start = random.randint(0, max(0, number_of_player_starts - 1))
            print(player_start)
            # Notify the server that we want to start the episode at the
            # player_start index. This function blocks until the server is ready
            # to start the episode.
            print('Starting new episode...')
            client.start_episode(player_start)
            
            control = None
            previous_loc = scene.player_start_spots[player_start].location
            distance = 0
            distance_step = 0

            # Iterate every frame in the episode.
            for frame in range(0, frames_per_episode):
                
                # Read the data produced by the server this frame.
                measurements, sensor_data = client.read_data()

                
                # Print some of the measurements.
                print_measurements(measurements)

                # Save the images to disk if requested.
                if args.save_images_to_disk and frame%2==0:
                    for name, measurement in sensor_data.items():
                        filename = args.out_filename_format.format(episode, name, frame)
                        measurement.save_to_disk(filename)

                # Calculate travelled distance
                current_loc = measurements.player_measurements.transform.location
                ddelta= np.linalg.norm(np.array((previous_loc.x, previous_loc.y, \
                     previous_loc.z)) - np.array((current_loc.x, current_loc.y, current_loc.z)))
                distance += ddelta
                distance_step += ddelta
                print(distance)
                print(distance_step)
                print(current_loc)
                previous_loc = current_loc


                # Now we have to send the instructions to control the vehicle.
                # If we are in synchronous mode the server will pause the
                # simulation until we send this control.

                # Check if the frame should actually be used to control the vehicle
                # Because a default fps should be assigned in the beginning and we need fpm
                if distance_step>=1/fpm:
                    # The frame should be used to control the vehicle
                    # because the distance step is reached
                    control = measurements.player_measurements.autopilot_control
                    control.steer += random.uniform(-0.1, 0.1)
                    distance_step -= 1/fpm
                    print("Distance Reduced: " + str(distance_step) + "\n")
                
                #else:
                    # The frame should not be used
                    # we should does send the previous control command
                    #control = previous_control
                

                client.send_control(control)

def make_carla_settings(args):
    # Create a CarlaSettings object. This object is a wrapper around
    # the CarlaSettings.ini file.
    settings = CarlaSettings()
    settings.set(
        SynchronousMode=True,
        SendNonPlayerAgentsInfo=True,
        NumberOfVehicles=20,
        NumberOfPedestrians=40,
        WeatherId=random.choice([1, 3, 7, 8, 14]),
        QualityLevel=args.quality_level)
    settings.randomize_seeds()

    # Now we want to add the camera to the player vehicle.

    # The default camera captures RGB images of the scene.
    camera0 = Camera('CameraRGB')
    # Set image resolution in pixels.
    camera0.set_image_size(800, 600)
    # Set its position relative to the car in meters.
    camera0.set_position(0.30, 0, 1.30)
    settings.add_sensor(camera0)
    return settings

def print_measurements(measurements):
    number_of_agents = len(measurements.non_player_agents)
    player_measurements = measurements.player_measurements
    message = 'Vehicle at ({pos_x:.1f}, {pos_y:.1f}), '
    message += '{speed:.0f} km/h, '
    message += 'Collision: {{vehicles={col_cars:.0f}, pedestrians={col_ped:.0f}, other={col_other:.0f}}}, '
    message += '{other_lane:.0f}% other lane, {offroad:.0f}% off-road, '
    message += 'Scene time: {scene_time}'
    message += '({agents_num:d} non-player agents in the scene)'
    message = message.format(
        pos_x=player_measurements.transform.location.x,
        pos_y=player_measurements.transform.location.y,
        speed=player_measurements.forward_speed * 3.6, # m/s -> km/h
        col_cars=player_measurements.collision_vehicles,
        col_ped=player_measurements.collision_pedestrians,
        col_other=player_measurements.collision_other,
        other_lane=100 * player_measurements.intersection_otherlane,
        offroad=100 * player_measurements.intersection_offroad,
        scene_time=measurements.game_timestamp,
        agents_num=number_of_agents)
    print_over_same_line(message)

def main():
    argparser = argparse.ArgumentParser(description=__doc__)
    # Option to set the host IP address
    argparser.add_argument(
        '--host',
        metavar='H',
        default='localhost',
        help='IP of the host server (default: localhost)')
    # Option to set the port number
    argparser.add_argument(
        '-p', '--port',
        metavar='P',
        default=2000,
        type=int,
        help='TCP port to listen to (default: 2000)')
    # Option to enable quality switching
    argparser.add_argument(
        '-q', '--quality-level',
        choices=['Low', 'Epic'],
        type=lambda s: s.title(),
        default='Epic',
        help='graphics quality level, a lower level makes the simulation run considerably faster.')
    # Option to let the user save the camera images to the disk
    argparser.add_argument(
        '-i', '--images-to-disk',
        action='store_true',
        dest='save_images_to_disk',
        help='save images to disk')
    argparser.add_argument(
        '-c', '--carla-settings',
        metavar='PATH',
        dest='settings_filepath',
        default=None,
        help='Path to a "CarlaSettings.ini" file')

    args = argparser.parse_args()

    logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.INFO)

    args.out_filename_format = '_out/episode_{:0>4d}/{:s}/{:0>6d}'


    while True:
        try:
            # Run the client code
            run_carla_client(args)

            print('Done.')
            return

        except TCPConnectionError as error:
            logging.error(error)
            time.sleep(1)


if __name__ == '__main__':

    try:
        main()
    except KeyboardInterrupt:
        print('\nCancelled by user. Bye!')
