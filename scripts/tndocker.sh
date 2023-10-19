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
    sleep 0.1 & tnSpin "UP"
elif [ "$action" == "down" ]; then
    sleep 0.1 & tnSpin "DOWN"
elif [ "$action" == "start" ]; then
    sleep 0.1 & tnSpin "START"
elif [ "$action" == "restart" ]; then
    sleep 0.1 & tnSpin "RESTART"
elif [ "$action" == "stop" ]; then
    sleep 0.1 & tnSpin "STOP"
elif [ "$action" == "list" ]; then
    sleep 0.1 & tnSpin "LIST"
elif [ "$action" == "install" ]; then

    containerName=$id
    containerDir="$dockerhome/$containerName"
    composeFile="$containerDir/docker-compose.yml"
    composeFileDistant="$github_link/containers/$containerName.yml"
    envFile="$containerDir/.env"
    envFileDistant="$github_link/containers/$containerName.conf"
    sleep 0.1 & tnSpin "------------------------------------------"
    sleep 0.1 & tnSpin "Installing container : $containerName"
    (tnExec "mkdir -p '$containerDir'" $logfile) & tnSpin "Creating main directory"
    (tnExec "tnDownload '$composeFileDistant' '$composeFile' '$ENV'" $logfile) & tnSpin "Downloading docker-compose.yml file"
    (tnExec "tnDownload '$envFileDistant' '$envFile' '$ENV'" $logfile) & tnSpin "Downloading .env file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$composeFile'" $logfile) & tnSpin "Modifying DOCKER_HOME docker-compose.yml file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$dockerhome' '$envFile'" $logfile) & tnSpin "Modifying DOCKER_HOME .env file"
    tnAskUserFromFile $envFile
    (tnExec "tnAutoFromFile $envFile $composeFile" $logfile) & tnSpin "Generating auto variables"
    (tnExec "tnCreateDirFromFile $envFile $" $logfile) & tnSpin "Creating container directories"
    (tnExec "chown docker:docker $containerDir -R" $logfile) & tnSpin "Changing container owner"

else
    echo "Invalid action"
fi