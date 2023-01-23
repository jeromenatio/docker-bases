#!/bin/bash

# Take two arguments, the first is the action (stop, remove, start) and the second is the container id
action="$1"
id="$2"

if [ "$action" == "remove" ]; then
    if [ "$id" == "all" ]; then
        # Stop all running containers
        docker container stop $(docker container ls -q)
        # Remove all existing containers and their associated volumes
        docker container rm -v $(docker container ls -a -q)
    else
        # Stop the specified container
        docker container stop $id
        # Remove the specified container and its associated volumes
        docker container rm -v $id
    fi
elif [ "$action" == "stop" ]; then
    if [ "$id" == "all" ]; then
        # Stop all running containers
        docker container stop $(docker container ls -q)
    else
        # Stop the specified container
        docker container stop $id
    fi
elif [ "$action" == "start" ]; then
    if [ "$id" == "all" ]; then
        # Start all stopped containers
        docker container start $(docker container ls -a -q)
    else
        # Start the specified container
        docker container start $id
    fi
else
    echo "Invalid action"
fi