#!/bin/bash
#
# Take two arguments, the first is the action (stop, remove, start, list) and the second is the container id or network name
action="$1"
id="$2"
directories=("${@:3}")
dockerhome="[DOCKER_HOME]"
envfile="[DOCKER_HOME]/.env"
utilsfile="[UTILS_FILES]"

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
elif [ "$action" == "restart" ]; then
    if [ "$id" == "all" ]; then
        # Start all stopped containers
        containers=$(docker container ls -a -q)
        if [ -z "$containers" ]; then
            echo "No containers found"
        else
            docker container restart $containers
        fi
    else
        # Start the specified container
        if docker container restart $id; then
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
elif [ "$action" == "up" ]; then
    # Get dir in docker
    file_path=$id
    file_name=${file_path%.*}
    dir_name=${file_name##*/}
    mkdir -p "$DOCKER_HOME/$dir_name"

    # Loop through the directories and create them
    for directory in "${directories[@]}"; do
        mkdir -p "$DOCKER_HOME/$dir_name/$directory"
    done

    # Copy docker compose to directory
    file_dest="$DOCKER_HOME/$dir_name/docker-compose.yml"
    mv $id $file_dest

    # Special cases : Remove exim
    if [ "$dir_name" == "mailserver" ]; then
        apt-get remove --purge exim4 exim4-base exim4-config exim4-daemon-light
    fi

    # Compose up
    eval "docker-compose -f $file_dest --env-file $envfile down --volumes --remove-orphans"
    eval "docker-compose -f $file_dest --env-file $envfile up -d --force-recreate --build" 
elif [ "$action" == "down" ]; then

    # destination file
    file_dest="$DOCKER_HOME/$id/docker-compose.yml"

    # Compose down
    eval "docker-compose -f $file_dest --env-file $envfile down --volumes --remove-orphans" 
else
    echo "Invalid action"
fi