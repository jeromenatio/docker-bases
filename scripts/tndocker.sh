#!/bin/bash

# GLOBALS
DOCKER_HOME="[DOCKER_HOME]"
ENV_FILE="[DOCKER_HOME]/.env"
UTILS_FILE="[UTILS_FILES]"
GITHUB="[GITHUB]"
LOG_FILE="[LOG_FILE]"
_UID="[_UID]"
_GID="[_GID]"

# GET UTILS FUNCTIONS
source $UTILS_FILE

# PARAMS
action="$1"
id="$2"
option="$3"

# CHECK FOR ACTIONS
if [ "$action" == "up" ]; then

    # Special cases : Remove exim
    [ "$id" == "mailserver" ] && apt-get remove --purge exim4 exim4-base exim4-config exim4-daemon-light

    # Base paths to install and download
    baseDir="$DOCKER_HOME/$id"
    envFileTemp="$baseDir/.envtemp"
    (tnExec "tnDownload '$GITHUB/containers/$id/.env' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
    composeFile="$baseDir/docker-compose.yml"
    envFile="$baseDir/.env"
    if tnIsMultiInstance $envFileTemp; then
        if [ -z "$option" ]; then
            tnDisplay "Container $id is a multi instance container, please provide instance name as 3rd option !!\n\n" "$darkYellowColor"
            exit 1  
        else            
            composeFile="$baseDir/$option/docker-compose.yml"    
            envFile="$baseDir/$option/.env"
            if [ ! -f "$composeFile" ]; then
                option_clean="${option//./-}" 
                composeFile="$baseDir/$option_clean/docker-compose.yml"    
                envFile="$baseDir/$option_clean/.env"
                if [ ! -f "$composeFile" ]; then
                    tnDisplay "The instance has not been found !!\n\n" "$darkYellowColor"
                    exit 1 
                fi
            fi
        fi
    fi
    
    # Compose up    
    eval "docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile down --volumes --remove-orphans"
    eval "docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile up -d --force-recreate --build" 
    (tnExec "rm '$envFileTemp'" $LOG_FILE) & tnSpin "Removing temp files"  

elif [ "$action" == "down" ]; then

    # Base paths to install and download
    containerName=$id
    containerBaseDir="$DOCKER_HOME/$containerName"
    envFileDistant="$GITHUB/containers/$containerName/.env"
    envFileTemp="$containerBaseDir/.envtemp"
    (tnExec "tnDownload '$envFileDistant' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
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
            eval "docker-compose -f $composeFileFinal --env-file $ENV_FILE --env-file $envFileFinal down --volumes --remove-orphans"
        fi
    else
        # Compose up    
        eval "docker-compose -f $composeFileFinal --env-file $ENV_FILE --env-file $envFileFinal down --volumes --remove-orphans" 
    fi 
    (tnExec "rm '$envFileTemp'" $LOG_FILE) & tnSpin "Removing temp files"

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
    localBaseDir="$DOCKER_HOME/$id"
    distantBaseDir="$GITHUB/containers/$id"
    envFile="$localBaseDir/.env"

    # Installing based on .env file
    tnDisplay "# ------------------------------------------\n" "$darkBlueColor"
    tnDisplay "# INSTALLING CONTAINER : $id\n" "$darkBlueColor"
    (tnExec "mkdir -p '$localBaseDir'" $LOG_FILE) & tnSpin "Creating container local base directory"
    (tnExec "tnDownloadFromFile $distantBaseDir $localBaseDir" $LOG_FILE) & tnSpin "Downloading files (.env, compose, dockerfile...)"
    (tnExec "tnSetGlobalsFromFile $localBaseDir" $LOG_FILE) & tnSpin "Modifying DOCKER_HOME, UID, GID in main .env file"
    tnAskUserFromFile $localBaseDir
    (tnExec "tnAutoFromFile $localBaseDir" $LOG_FILE) & tnSpin "Generating auto variables"
    (tnExec "tnCreateDirFromFile $localBaseDir" $LOG_FILE) & tnSpin "Creating container directories"
    instance=$(tnGetInstancePathFromFile $envFile) 
    tnIsMultiInstance "$envFile" && (tnExec "tnMoveFilesToInstance $localBaseDir" "$LOG_FILE" & tnSpin "Moving files to instance")
    (tnExec "chown -R docker:docker $localBaseDir" $LOG_FILE) & tnSpin "Changing container owner"

else
    echo "Invalid action"
fi