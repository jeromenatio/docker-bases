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

# SUPABASE JWT SECRET AND JWT KEY CREATION
function tnSupabase(){
    local dir="$1"
    local stamp=$(date +%s)
    local stamp90=$((stamp + 90 * 365 * 24 * 3600))
    
    # Debug
    echo "----------------------"
    echo "SUPABASE DIR : $dir"
    echo "SUPABASE STAMP : $stamp"
    echo "SUPABASE DIR : $stamp90"
}

# CHECK FOR ACTIONS
if [ "$action" == "up" ]; then

    # Base paths to install and download
    baseDir="$DOCKER_HOME/$id"
    envFileTemp="$baseDir/.envtemp"
    envFileTempDistant="$GITHUB/containers/$id/.env"
    (tnExec "tnDownload '$envFileTempDistant' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
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
    eval "docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile up -d --build"
    
    # Remove temp files
    (tnExec "rm '$envFileTemp'" $LOG_FILE) & tnSpin "Removing temp files"  

elif [ "$action" == "uph" ]; then

    # Base paths to install and download
    baseDir="$DOCKER_HOME/$id"
    envFileTemp="$baseDir/.envtemp"
    envFileTempDistant="$GITHUB/containers/$id/.env"
    (tnExec "tnDownload '$envFileTempDistant' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
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

    # Compose up hard way
    docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile down --volumes --remove-orphans
    docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile up -d --force-recreate --build
    
    # Remove temp files
    (tnExec "rm '$envFileTemp'" $LOG_FILE) & tnSpin "Removing temp files"  

elif [ "$action" == "down" ]; then

    # Base paths to install and download
    baseDir="$DOCKER_HOME/$id"
    envFileTemp="$baseDir/.envtemp"
    envFileTempDistant="$GITHUB/containers/$id/.env"
    (tnExec "tnDownload '$envFileTempDistant' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
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

    # Compose down    
    eval "docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile down"
    
    # Remove temp files
    (tnExec "rm '$envFileTemp'" $LOG_FILE) & tnSpin "Removing temp files"

elif [ "$action" == "downh" ]; then

    # Base paths to install and download
    baseDir="$DOCKER_HOME/$id"
    envFileTemp="$baseDir/.envtemp"
    envFileTempDistant="$GITHUB/containers/$id/.env"
    (tnExec "tnDownload '$envFileTempDistant' '$envFileTemp' '$ENV'" $LOG_FILE) & tnSpin "Downloading .env file"
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

    # Compose down    
    docker-compose -f $composeFile --env-file $ENV_FILE --env-file $envFile down --volumes --remove-orphans
    
    # Remove temp files
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
    disBaseDir="$GITHUB/containers/$id"
    locBaseDir="$DOCKER_HOME/$id"
    disEnvTemp="$disBaseDir/.env"
    locEnvTemp="$locBaseDir/.env"

    # Create container base directory 
    tnDisplay "# ------------------------------------------\n" "$darkBlueColor"
    tnDisplay "# INSTALLING CONTAINER : $id\n" "$darkBlueColor"
    (tnExec "mkdir -p '$locBaseDir'" $LOG_FILE) & tnSpin "Creating base directory container"

    # Tempory variables store
    varsTemp="$locBaseDir/.vars"
    [ -e "$varsTemp" ] && rm "$varsTemp"
    touch "$varsTemp"

    # Install and download files
    (tnExec "tnDownload $disEnvTemp $locEnvTemp" $LOG_FILE) & tnSpin "Downloading .env file"
    (tnExec "tnSetStamps $locEnvTemp" $LOG_FILE) & tnSpin "Setting timestamps in .env file"
    (tnExec "tnSetGlobals $locEnvTemp" $LOG_FILE) & tnSpin "Setting globals (DOCKER_HOME, UID, GID ...) in .env file"    
    tnAskUserFromFile $locEnvTemp $varsTemp
    (tnExec "tnAutoVarsFromFile $locEnvTemp $varsTemp" $LOG_FILE) & tnSpin "Generating auto variables from .env file"
    (tnExec "tnSetVars $locEnvTemp $varsTemp" $LOG_FILE ) & tnSpin "Settings user/auto defined vars in .env file"
    (tnExec "tnCreateNetworksFromFile $locEnvTemp" $LOG_FILE) & tnSpin "Creating custom networks from .env file"
    (tnExec "tnCreateDirsFromFile $locEnvTemp" $LOG_FILE) & tnSpin "Creating container directories from .env file"
    instanceDir=$(tnGetInstancePathFromFile $locEnvTemp)
    instanceEnv="$instanceDir/.env"
    instanceVars="$instanceDir/.vars"
    
    # Download all files and Set Stamps, Globals, Vars
    tnDownloadAndSetAllFiles $locEnvTemp $disBaseDir $varsTemp
    tnIsMultiInstance "$locEnvTemp" && (tnExec "mv $varsTemp $instanceVars" "$LOG_FILE" & tnSpin "Moving .vars to instance directory")
    tnIsMultiInstance "$locEnvTemp" && (tnExec "mv $locEnvTemp $instanceEnv" "$LOG_FILE" & tnSpin "Moving .env to instance directory")
    
    # SPECIAL ACTIONS
    
    # -- Supabase
    if [ "$id" == "supabase" ]; then 
        tnSupabaseDir=$(tnIsMultiInstance "$locEnvTemp" && echo "$instanceDir" || echo "$locBaseDir")
        tnSupabase "$tnSupabaseDir" #> /dev/null 2>&1
        sleep 0.1 & tnSpin "Creating JWT secret and signed key for supabase"
    fi

    # -- Mailserver
    if [ "$id" == "mailserver" ]; then 
        apt-get remove --purge exim4 exim4-base exim4-config exim4-daemon-light > /dev/null 2>&1
        sleep 0.1 & tnSpin "Removing exim to replace by mailserver"
    fi

    # Change instance owner to docker
    (tnExec "chown -R docker:docker $instanceDir" $LOG_FILE) & tnSpin "Changing container instance owner to docker"

else
    echo "Invalid action"
fi