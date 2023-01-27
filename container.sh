#!/bin/bash

# Take two arguments, the first is the action (stop, remove, start, list) and the second is the container id or network name
action="$1"
id="$2"

if [ "$action" == "remove" ]; then
    if [ "$id" == "all" ]; then
        # Stop all running containers
        containers=$(docker container ls -q)
        if [ -n "$containers" ]; then
            docker container stop $containers
        fi
        # Remove all existing containers and their associated volumes
        containers=$(docker container ls -a -q)
        if [ -n "$containers" ]; then
            docker container rm -v $containers
        else
            echo "No containers found"
        fi
    else
        # Stop the specified container
        if docker container stop $id; then
            # Remove the specified container and its associated volumes
            docker container rm -v $id
        else
            echo "Container $id not found"
        fi
    fi
elif [ "$action" == "stop" ]; then
    if [ "$id" == "all" ]; then
        # Stop all running containers
        containers=$(docker container ls -q)
        if [ -z "$containers" ]; then
            echo "No running containers found"
        else
            docker container stop $containers
        fi
    else
        # Stop the specified container
        if docker container stop $id; then
            :
        else
            echo "Container $id not found"
        fi
    fi
elif [ "$action" == "start" ]; then
    if [ "$id" == "all" ]; then
        # Start all stopped containers
        containers=$(docker container ls -a -q)
        if [ -z "$containers" ]; then
            echo "No containers found"
        else
            docker container start $containers
        fi
    else
        # Start the specified container
        if docker container start $id; then
            :
        else
            echo "Container $id not found"
        fi
    fi
elif [ "$action" == "list" ]; then
    if [ -z "$id" ]; then
        echo "Please provide a network name"
    else
        if [ "$id" == "all" ]; then
            networks=$(docker network ls -q)
            for network in $networks; do
                containers=$(docker container ls --filter "network=$network" -q)
                if [ -n "$containers" ]; then
                    name=$(docker network inspect $network --format='{{.Name}}')
                    id=$(docker network inspect $network --format='{{.Id}}')
                    echo "** $name"
                    for container in $containers; do
                        name=$(docker container inspect $container --format='{{.Name}}' | tr -d '/')
                        id=$(docker container inspect $container --format='{{.Id}}')
                        echo "     - $name"
                    done
                fi
            done
        else
            containers=$(docker container ls --filter "network=$id" -q)
            if [ -z "$containers" ]; then
                echo "No containers found in network $id"
            else
                name=$(docker network inspect $id --format='{{.Name}}')
                id=$(docker network inspect $id --format='{{.Id}}')
                echo "** $name"
                for container in $containers; do
                    name=$(docker container inspect $container --format='{{.Name}}' | tr -d '/')
                    id=$(docker container inspect $container --format='{{.Id}}')
                    echo "     - $name"
                done
            fi
        fi
    fi
else
    echo "Invalid action"
fi