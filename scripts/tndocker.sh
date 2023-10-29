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
    sleep 0.1 & tnSpin "DOWN"
elif [ "$action" == "start" ]; then
    sleep 0.1 & tnSpin "START"
elif [ "$action" == "restart" ]; then
    sleep 0.1 & tnSpin "RESTART"
elif [ "$action" == "stop" ]; then
    sleep 0.1 & tnSpin "STOP"
elif [ "$action" == "list" ]; then

    # Run `docker-compose ls --all` and store the results in a variable
    compose_ls_output=$(docker-compose ls --all)

    # Parse the `docker-compose ls` output to extract project names and config file paths
    while read -r line; do

        # Skip the header and empty lines
        if [[ "$line" == Name* || "$line" == NAME* || "$line" == Project* || "$line" == PROJECT* || -z "$line" ]]; then
            continue
        fi

        # Split the line into project name and config file path
        project_name=$(echo "$line" | awk '{print $1}')
        project_status=$(echo "$line" | awk '{print $2}')
        config_file=$(echo "$line" | awk '{print $3}')
        echo $project_name
        echo $project_status
        echo $config_file
        echo "--------"

    done <<< "$compose_ls_output"

elif [ "$action" == "install" ]; then

    # Base paths to install and download
    containerName=$id
    containerBaseDir="$dockerhome/$containerName"
    composeFileDistant="$github_link/containers/$containerName/docker-compose.yml"
    envFileDistant="$github_link/containers/$containerName/.env"
    composeFileTemp="$containerBaseDir/docker-compose.yml"
    envFileTemp="$containerBaseDir/.env"

    # Installing based on .env file
    sleep 0.1 & tnSpin "------------------------------------------"
    sleep 0.1 & tnSpin "Installing container : $containerName"
    (tnExec "mkdir -p '$containerBaseDir'" $logfile) & tnSpin "Creating container base directory"
    (tnExec "tnDownload '$composeFileDistant' '$composeFileTemp' '$ENV'" $logfile) & tnSpin "Downloading docker-compose.yml file"
    (tnExec "tnDownload '$envFileDistant' '$envFileTemp' '$ENV'" $logfile) & tnSpin "Downloading .env file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$composeFileTemp'" $logfile) & tnSpin "Modifying DOCKER_HOME docker-compose.yml file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$envFileTemp'" $logfile) & tnSpin "Modifying DOCKER_HOME .env file"
    tnAskUserFromFile $envFileTemp $composeFileTemp
    (tnExec "tnAutoFromFile $envFileTemp $composeFileTemp" $logfile) & tnSpin "Generating auto variables"
    (tnExec "tnCreateDirFromFile $envFileTemp" $logfile) & tnSpin "Creating container directories"
    (tnExec "chown -R docker:docker $containerDir" $logfile) & tnSpin "Changing container owner"
    if tnIsMultiInstance $envFileTemp; then
        instance=$(tnGetInstancePathFromFile $envFileTemp)  
        composeFileFinal="$instance/docker-compose.yml"    
        envFileFinal="$instance/.env"
        (tnExec "mv '$composeFileTemp' '$composeFileFinal'" $logfile) & tnSpin "Moving compose file"
        (tnExec "mv '$envFileTemp' '$envFileFinal'" $logfile) & tnSpin "Moving env file"
        (tnExec "chown -R docker:docker $instance" $logfile) & tnSpin "Changing container instance owner"
    fi

else
    echo "Invalid action"
fi