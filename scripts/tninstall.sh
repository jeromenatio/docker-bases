#!/bin/bash

# GLOBALS
ENV="prod"
GITHUB=$( [ "$ENV" != "dev" ] &&  echo "https://raw.githubusercontent.com/jeromenatio/docker-bases/main" ) || echo "/home/_local"
DOCKER_HOME="/home/tndocker"
DEPENDENCIES=("curl" "id" "getent" "uuidgen")
DEFAULT_CONTAINERS=("nginxproxy")
UTILS_FILE="/usr/local/bin/tnutils"
TNDOCKER_FILE="/usr/local/bin/tndocker"
ENV_FILE="$DOCKER_HOME/.env"
LOG_FILE="./install.log"

# CLEAR LOG FILE
[ -e "$LOG_FILE" ] && rm "$LOG_FILE"

# DOWNLOAD AND SOURCE UTILITIES
[ "$ENV" != "dev" ] && curl -Ls -H 'Cache-Control: no-cache' "$GITHUB/scripts/tnutils.sh" -o "$UTILS_FILE" || cp "$GITHUB/scripts/tnutils.sh" "$UTILS_FILE"
chmod +x $UTILS_FILE
source $UTILS_FILE

# EXPLAIN WHAT THE SCRIPT WILL DO
clear
tnDisplay "#  DOCKER INSTALLATION SCRIPT \n" "$darkBlueColor"
tnDisplay "#  This script will install docker and docker-compose \n" "$darkBlueColor"
tnDisplay "#  along with basics containers to handle redirections, ssl and basics security. \n" "$darkBlueColor"
tnDisplay "#  You will be asked to select additional containers or programs. \n" "$darkBlueColor"
tnDisplay "#  All the required password will be generated randomly for obvious security reasons. \n" "$darkBlueColor"
tnDisplay "#  You can find them in the directory of each installed container in the .env file. \n" "$darkBlueColor"
tnDisplay "#  ---------------------------------------------------------------------------------- \n\n" "$darkBlueColor"

# INSTALL DEPENDENCIES
tnAreCommandsMissing "$DEPENDENCIES" && (tnExec "apt-get update && apt-get install -y curl util-linux coreutils uuid-runtime" "$LOG_FILE" & tnSpin "Installing script dependencies")

# GET/CREATE DOCKER _GID AND _UID
[ ! getent group docker > /dev/null 2>&1 ] && groupadd docker
_GID=$(getent group docker | cut -d: -f3)
[ ! id -u docker > /dev/null 2>&1 ] && useradd -u $_GID -g docker docker
_UID=$(id -u docker)
sleep 0.1 & tnSpin "Docker GID and UID found $_GID $_UID"

# INSTALL DOCKER
tnIsCommandMissing docker && tnInstallDocker "$LOG_FILE"

# INSTALL DOCKER-COMPOSE
latest_version=$(tnGetLatestRelease "docker" "compose")
tnIsCommandMissing docker-compose && tnInstallDockerCompose "$(uname -s)" "$(uname -m)" $latest_version $LOG_FILE

# IF HOME ALREADY EXISTS STOP THE SCRIPT
if [[ -d "$DOCKER_HOME" ]]; then
    tnDisplay "'$DOCKER_HOME' already exists !!\n\n" "$darkYellowColor"
    exit 1    
fi

# CREATE DOCKER HOME DIRECTORY
(tnExec "mkdir -p $DOCKER_HOME" $LOG_FILE) & tnSpin "Creating DOCKER HOME directory $DOCKER_HOME"
(tnExec "chown -R docker:docker $DOCKER_HOME" $LOG_FILE) & tnSpin "Changing docker home owner"

# DOWNLOAD MAIN .env FILE, MODIFY GLOBALS, ASK USER RELATED QUESTIONS AND CREATE NETWORKS
(tnExec "tnDownload '$GITHUB/.env' '$ENV_FILE'" $LOG_FILE) & tnSpin "Downloading main .env file"
(tnExec "tnSetGlobals '$ENV_FILE'" $LOG_FILE) & tnSpin "Modifying DOCKER_HOME, UID, GID in main .env file"
tnAskUserFromFile $DOCKER_HOME
(tnExec "tnAutoFromFile $DOCKER_HOME" $LOG_FILE) & tnSpin "Generating auto variables"
(tnExec "tnCreateNetworkFromFile $DOCKER_HOME" $LOG_FILE) & tnSpin "Creating custom docker networks"

# INSTALL TNDOCKER COMMAND FILE AND MODIFY GLOBALS
(tnExec "tnDownload '$GITHUB/scripts/tndocker.sh' '$TNDOCKER_FILE'" $LOG_FILE)
(tnExec "tnSetGlobals '$TNDOCKER_FILE'" $LOG_FILE) & tnSpin "Modifying DOCKER_HOME, UID, GID in main .env file"
(tnExec "chmod +x '$TNDOCKER_FILE'" $LOG_FILE) & tnSpin "Changing permissions on tndocker commands file"

# INSTALL DEFAULT CONTAINERS
for i in "${DEFAULT_CONTAINERS[@]}"; do
    tndocker install $i
done

# CHANGING OWNER ON DOCKER DIRECTORIES AND FILES
(tnExec "chown -R docker:docker $DOCKER_HOME" $LOG_FILE) & tnSpin "Changing docker home owner"
