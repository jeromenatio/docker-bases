#!/bin/bash

# GLOBALS FOR TEST
ENV="dev"
github_link="https://raw.githubusercontent.com/jeromenatio/docker-bases/main"
if [ "$ENV" == "dev" ]; then
    github_link="/home/_local"
fi

# PARAMETERS
DOCKER_HOME="/home/tndocker"
toinstall=("fail2ban (helps again brute force attacks)"  "ufw (basic firewall)"  "invoice ninja (easy billing)" "directus (make an api with no code and cool ui)" )
dependencies=("curl" "id" "getent" "uuidgen")
defaultContainers=("nginxproxy")
utilsfile="/usr/local/bin/tnutils"
utilsfile_distant="$github_link/scripts/tnutils.sh"
dockerutiliesfile="/usr/local/bin/tndocker"
dockerutiliesfile_distant="$github_link/scripts/tndocker.sh"
envfile="$DOCKER_HOME/.env"
envfile_distant="$github_link/.env"
logfile="./install.log"
uname_s=$(uname -s)
uname_m=$(uname -m)
repo_owner="docker"
repo_name="compose"

# CLEAR LOG FILE
if test -e $logfile; then
    rm $logfile
fi

# DOWNLOAD AND SOURCE UTILITIES
tnPoorDownload(){
    if [ "$3" == "dev" ]; then
        echo "cp $1 $2"
        cp "$1" "$2"
    else
        curl -Ls -H 'Cache-Control: no-cache' "$1" -o "$2" 
    fi
}
tnPoorDownload "$utilsfile_distant" "$utilsfile" "$ENV"
chmod +x $utilsfile
source $utilsfile

# Docker compose latest version
latest_version=$(tnGetLatestRelease $repo_owner $repo_name)

# CLEAR PREVIOUS CLI STUFF
clear

# EXPLAIN WHAT THE SCRIPT WILL DO
tnDisplay "#  DOCKER INSTALLATION SCRIPT \n" "$darkBlueColor"
tnDisplay "#  This script will install docker and docker-compose \n" "$darkBlueColor"
tnDisplay "#  along with basics containers to handle redirections, ssl and basics security. \n" "$darkBlueColor"
tnDisplay "#  The followings containers are installed by default: \n" "$darkBlueColor"
tnDisplay "#  nginx proxy manager, portainer, vscode, adminer. \n" "$darkBlueColor"
tnDisplay "#  You will be asked to select additional containers or programs. \n" "$darkBlueColor"
tnDisplay "#  All the required password will be generated randomly for obvious security reasons. \n" "$darkBlueColor"
tnDisplay "#  You can find them in the directory of each installed container in the .env file. \n" "$darkBlueColor"
tnDisplay "#  ---------------------------------------------------------------------------------- \n\n" "$darkBlueColor"

# MAKE USER CHOOSE WHAT TO INSTALL
# You should pass it an array (toinstall) in which each entry should be formatted as following:
# "id (description)""
# example: "fail2ban (helps again brute force attacks)"
# you will get the results of user choice in "install_list" variable (associative array)
# tnSelect install_list toinstall "Please choose what you want to install"

# INSTALL DEPENDENCIES
if tnAreCommandsMissing $dependencies; then
    (tnExec "apt-get update && apt-get install -y curl util-linux coreutils uuid-runtime" $logfile) & tnSpin "Installing script dependencies"
else
    sleep 0.1 & tnSpin "Script dependencies already installed"
fi

# CREATE DOCKER GROUP AND GET GID
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker
fi
_GID=$(getent group docker | cut -d: -f3)
sleep 0.1 & tnSpin "Docker gid found $_GID"

# CREATE DOCKER USER AND GET UID
if ! id -u docker > /dev/null 2>&1; then
    useradd -u $_GID -g docker docker
fi
_UID=$(id -u docker)
sleep 0.1 & tnSpin "Docker uid found $_UID"

# INSTALL DOCKER
if tnIsCommandMissing docker; then
    tnInstallDocker $logfile
else
    sleep 0.1 & tnSpin "Docker already installed"
fi

# INSTALL DOCKER-COMPOSE
if tnIsCommandMissing docker-compose; then
   tnInstallDockerCompose $uname_s $uname_m $latest_version $logfile
else
    sleep 0.1 & tnSpin "Docker compose already installed"
fi

# CHECK DOCKER HOME
tnIsHomeEmpty
(tnExec "mkdir -p $DOCKER_HOME" $logfile) & tnSpin "Creating DOCKER HOME directory $DOCKER_HOME"

# DOWNLOAD MAIN .env FILE AND MODIFY DOCKER_HOME, GID, UID
envfile="$DOCKER_HOME/.env"
(tnExec "tnDownload '$envfile_distant' '$envfile' '$ENV'" $logfile) & tnSpin "Downloading main .env file"
(tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$DOCKER_HOME' '$envfile'" $logfile)
(tnExec "tnReplaceStringInFile '\\[UID\\]' '$_UID' '$envfile'" $logfile)
(tnExec "tnReplaceStringInFile '\\[GID\\]' '$_GID' '$envfile'" $logfile) & tnSpin "Modifying DOCKER_HOME, UID, GID in main .env file"

# ASK FOR DEFAULT CONFIGS IN MAIN .env FILE
tnAskUserFromFile $envfile
sleep 0.5 & tnSpin "Modifying main .env file"

# INSTALL TNDOCKER COMMAND
tndockerfile="/usr/local/bin/tndocker"
tndockerfile_distant="$github_link/scripts/tndocker.sh"
(tnExec "tnDownload '$tndockerfile_distant' '$tndockerfile' '$ENV'" $logfile) & tnSpin "Downloading tndocker commands file"
(tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$DOCKER_HOME' '$tndockerfile'" $logfile) & tnSpin "Updating tndocker commands"
(tnExec "chmod +x '$tndockerfile'" $logfile) & tnSpin "Changing permissions on tndocker commands file"

# INSTALL DEFAULT CONTAINERS
for i in "${defaultContainers[@]}"; do
    containerName=$i
    containerDir="$DOCKER_HOME/$containerName"
    composeFile="$containerDir/docker-compose.yml"
    composeFileDistant="$github_link/containers/$containerName.yml"
    envFile="$containerDir/.env"
    envFileDistant="$github_link/containers/$containerName.conf"
    sleep 0.1 & tnSpin "------------------------------------------"
    sleep 0.1 & tnSpin "Installing container : $containerName"
    (tnExec "mkdir -p '$containerDir'" $logfile) & tnSpin "Creating main directory"
    (tnExec "tnDownload '$composeFileDistant' '$composeFile' '$ENV'" $logfile) & tnSpin "Downloading docker-compose.yml file"
    (tnExec "tnDownload '$envFileDistant' '$envFile' '$ENV'" $logfile) & tnSpin "Downloading .env file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$DOCKER_HOME' '$composeFile'" $logfile) & tnSpin "Modifying DOCKER_HOME docker-compose.yml file"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$DOCKER_HOME' '$envFile'" $logfile) & tnSpin "Modifying DOCKER_HOME .env file"
    tnAskUserFromFile $envFile
    (tnExec "tnAutoFromFile $envFile" $logfile) & tnSpin "Generating auto variables"
    (tnExec "tnCreateDirFromFile $envFile" $logfile) & tnSpin "Creating container directories"
    #
done
