#!/bin/bash
#
# Take two arguments, the first is the action (stop, remove, start, list) and the second is the container id or network name
action="$1"
id="$2"
option="$3"
dockerhome="[DOCKER_HOME]"
envfile="[DOCKER_HOME]/.env"
utilsfile="[UTILS_FILES]"
github_link="[GITHUB_LINK]"
logfile="[LOG_FILE]"
uid="[UID]"
gid="[GID]"
source $utilsfile

if [ "$action" == "up" ]; then

    # Special cases : Remove exim
    if [ "$id" == "mailserver" ]; then
        apt-get remove --purge exim4 exim4-base exim4-config exim4-daemon-light
    fi

    # Base paths to install and download
    containerName=$id
    containerBaseDir="$dockerhome/$containerName"
    envFileDistant="$github_link/containers/$containerName/.env"
    envFileTemp="$containerBaseDir/.envtemp"
    (tnExec "tnDownload '$envFileDistant' '$envFileTemp' '$ENV'" $logfile) & tnSpin "Downloading .env file"
    composeFileFinal="$containerBaseDir/docker-compose.yml"
    envFileFinal="$containerBaseDir/.env"
    if tnIsMultiInstance $envFileTemp; then
        if [ -z "$option" ]; then
            sleep 0.1 & tnSpin "Container $id is a multi instance container, please provide instance name as 3rd option"
        else
            
            composeFileFinal="$containerBaseDir/$option/docker-compose.yml"    
            envFileFinal="$containerBaseDir/$option/.env"
            if [ ! -f "$composeFileFinal" ]; then
                option_clean="${option//./-}" 
                composeFileFinal="$containerBaseDir/$option_clean/docker-compose.yml"    
                envFileFinal="$containerBaseDir/$option_clean/.env"
            fi

            # Compose up    
            eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal down --volumes --remove-orphans"
            eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal up -d --force-recreate --build" 
        fi
    else
        # Compose up    
        eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal down --volumes --remove-orphans"
        eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal up -d --force-recreate --build" 
    fi 
    (tnExec "rm '$envFileTemp'" $logfile) & tnSpin "Removing temp files"  

elif [ "$action" == "down" ]; then

    # Base paths to install and download
    containerName=$id
    containerBaseDir="$dockerhome/$containerName"
    envFileDistant="$github_link/containers/$containerName/.env"
    envFileTemp="$containerBaseDir/.envtemp"
    (tnExec "tnDownload '$envFileDistant' '$envFileTemp' '$ENV'" $logfile) & tnSpin "Downloading .env file"
    composeFileFinal="$containerBaseDir/docker-compose.yml"
    envFileFinal="$containerBaseDir/.env"
    if tnIsMultiInstance $envFileTemp; then
        if [ -z "$option" ]; then
            sleep 0.1 & tnSpin "Container $id is a multi instance container, please provide instance name as 3rd option"
        else
            
            composeFileFinal="$containerBaseDir/$option/docker-compose.yml"    
            envFileFinal="$containerBaseDir/$option/.env"
            if [ ! -f "$composeFileFinal" ]; then
                option_clean="${option//./-}" 
                composeFileFinal="$containerBaseDir/$option_clean/docker-compose.yml"    
                envFileFinal="$containerBaseDir/$option_clean/.env"
            fi

            # Compose up    
            eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal down --volumes --remove-orphans"
        fi
    else
        # Compose up    
        eval "docker-compose -f $composeFileFinal --env-file $envfile --env-file $envFileFinal down --volumes --remove-orphans" 
    fi 
    (tnExec "rm '$envFileTemp'" $logfile) & tnSpin "Removing temp files"

elif [ "$action" == "start" ]; then
    sleep 0.1 & tnSpin "START function not yet implemented"
elif [ "$action" == "restart" ]; then
    sleep 0.1 & tnSpin "RESTART function not yet implemented"
elif [ "$action" == "stop" ]; then
    sleep 0.1 & tnSpin "STOP function not yet implemented"
elif [ "$action" == "list" ]; then

    # Run `docker-compose ls --all` and store the results in a variable
    compose_ls_output=$(docker-compose ls --all)

    # Set a flag to skip the first line (header)
    skip_line=true

    # Parse the `docker-compose ls` output to extract project names and config file paths
    while read -r line; do

        # Skip the header
        if [ "$skip_line" = true ]; then
            skip_line=false
            continue
        fi

        # Split the line into project name and status #
        project_name=$(echo "$line" | awk '{print $1}')
        project_status=$(echo "$line" | awk '{print $2}')
        config_file=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^[ \t]*//')

        if [ "$id" == "all" ] || [ "$id" == "$project_name" ]; then
            echo "** $project_name"

            # List containers, ports and networks
            container_names=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format "{{.Names}}")

            for container_name in $container_names; do                              
                container_ports=$(docker port "$container_name" | sed -e '/\[::\]:/d' -e 's/0.0.0.0://' -e 's/\/tcp//' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' | sed 's/ -> /->/g')
                if [ -z "$container_ports" ]; then
                    container_ports="no port forwarded"
                fi
                container_status=$(docker inspect -f '{{.State.Status}}' "$container_name")
                container_networks=$(docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}, {{end}}' "$container_name" | sed 's/, $//')
                echo -e "\t- $container_name\t\t[$container_status]\t[$container_ports]\t\t[$container_networks]"
            done
        fi

    done <<< "$compose_ls_output"

elif [ "$action" == "install" ]; then

    # Base paths to install and download
    localBaseDir="$dockerhome/$id"
    distantBaseDir="$github_link/containers/$id"
    envFile="$localBaseDir/.env"

    # Installing based on .env file
    sleep 0.1 & tnSpin "------------------------------------------"
    sleep 0.1 & tnSpin "Installing container : $id"
    (tnExec "mkdir -p '$localBaseDir'" $logfile) & tnSpin "Creating container local base directory"
    (tnExec "tnDownloadFromFile $localBaseDir" $logfile) & tnSpin "Downloading files (.env, compose, dockerfile...)"

    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$composeFileTemp'" $logfile) & tnSpin "Modifying DOCKER_HOME docker-compose.yml file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$envFile'" $logfile) & tnSpin "Modifying DOCKER_HOME .env file"
    
    tnAskUserFromFile $localBaseDir
    (tnExec "tnAutoFromFile $localBaseDir" $logfile) & tnSpin "Generating auto variables"
    (tnExec "tnCreateDirFromFile $localBaseDir" $logfile) & tnSpin "Creating container directories"
    if tnIsMultiInstance $envFile; then
        instance=$(tnGetInstancePathFromFile $envFile)
        #Move all files to instance directory

    fi
    (tnExec "chown -R docker:docker $localBaseDir" $logfile) & tnSpin "Changing container owner"

else
    echo "Invalid action"
fi