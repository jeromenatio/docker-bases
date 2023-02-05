#!/bin/bash
# This inscript will install the basics administration tools
# for a web server on debian based linux architecture.
# The structure is container based (DOCKER)

# FUNCTIONS
spin() {
  local text="$1"
  local pid=$!
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  local check_character="✔"
  local spin_color=36
  local text_color=96
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %10 ))
    printf "\033[${text_color}m\r\033[${spin_color}m${spin:$i:1} \033[${text_color}m$text\033[0m"
    sleep .1
  done
  printf "\033[${spin_color}m\r$check_character $text\033[0m\n"
}

tnexec() {
    local command=$1
    local logfile=$2
    eval "$command" >> "$logfile" 2>&1
}

install_docker(){
    local logfile=$1
    (tnexec "apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg lsb-release" $logfile) & spin "Installing docker dependencies"
    if [[ ! -e "/usr/share/keyrings/docker-archive-keyring.gpg" ]]; then
        (tnexec "curl -fsSL -H 'Cache-Control: no-cache' https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" $logfile) & spin "Downloading and saving docker key"
    fi
    (tnexec "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" $logfile) && spin "Modifying repositories source.list"
    (tnexec "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io" $logfile) & spin "Installing docker"
    sleep 0.1 & spin "$(docker --version) installed"
}

install_docker_compose(){
    local uname_s=$1
    local uname_m=$2
    local latest_version=$3
    local logfile=$4
    (tnexec "curl -Ls -H 'Cache-Control: no-cache' 'https://github.com/docker/compose/releases/download/$latest_version/docker-compose-$uname_s-$uname_m' -o /usr/local/bin/docker-compose" $logfile) & spin "Downloading docker-compose deb package"
    (tnexec "chmod +x /usr/local/bin/docker-compose" $logfile) & spin "Installing docker-compose"
    sleep 0.1 & spin "$(docker-compose --version) installed"
}

user_confirm() {
  local question=$1
  local yellow="\033[38;5;220m"
  local darker_yellow="\033[38;5;214m"
  local reset="\033[0m"
  echo -en "${yellow}? ${question} ${darker_yellow}(y/n) ${yellow}?${reset} "
  read answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    return 0 
  else
    return 1
  fi
}

generate_password() {
    LENGTH=$1
    LOWERCASE_CHARS=(a b c d e f g h j k m n p q r s t u v w x y z)
    UPPERCASE_CHARS=(A B C D E F G H J K M N P Q R S T U V W X Y Z)
    NUMBER_CHARS=(0 1 2 3 4 5 6 7 8 9)
    SPECIAL_CHARS=("!" "*")
    PASSWORD=""
    while [[ ${#PASSWORD} -lt $LENGTH ]]; do
        if [[ ${#PASSWORD} -lt 1 ]]; then
            PASSWORD+="${LOWERCASE_CHARS[$RANDOM % ${#LOWERCASE_CHARS[@]}]}"
        elif [[ ${#PASSWORD} -lt 2 ]]; then
            PASSWORD+="${UPPERCASE_CHARS[$RANDOM % ${#UPPERCASE_CHARS[@]}]}"
        elif [[ ${#PASSWORD} -lt 3 ]]; then
            PASSWORD+="${NUMBER_CHARS[$RANDOM % ${#NUMBER_CHARS[@]}]}"
        elif [[ ${#PASSWORD} -lt 4 ]]; then
            PASSWORD+="${SPECIAL_CHARS[$RANDOM % ${#SPECIAL_CHARS[@]}]}"
        else
            CHAR_POOL=( "${LOWERCASE_CHARS[@]}" "${UPPERCASE_CHARS[@]}" "${NUMBER_CHARS[@]}" "${SPECIAL_CHARS[@]}" )
            PASSWORD+="${CHAR_POOL[$RANDOM % ${#CHAR_POOL[@]}]}"
        fi
    done
    echo $PASSWORD
}

generate_dir(){
    local timestamp=$(date +%s)
    echo "/home/docker_$timestamp";
}

user_ask() {
  local question="$1"
  local default_value="$2"
  local variable="$3"
  local yellow="\033[38;5;220m"
  local darker_yellow="\033[38;5;214m"
  local reset="\033[0m"
  local default_display="leave blank to use default $default_value"
  if [[ "$default_value" == "GENPWD" ]]; then
    default_display="leave blank to generate random password"
    default_value="$(generate_password 10)"
  fi
  if [[ "$default_value" == "GENDIR" ]]; then
    default_display="leave blank to generate random dir path"
    default_value="$(generate_dir)"
  fi
  echo -en "${yellow}? ${question} ${darker_yellow}(${default_display}) ${yellow}?${reset} "
  read answer
  if [[ "$answer" == "" ]]; then
    eval "$variable=\"$default_value\""
  else
    eval "$variable=\"$answer\""
  fi
}

ask_questions_from_file() {
    local file=$1
    local declare matches
    while read line; do
        if [[ $line =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < $file
    for match in "${matches[@]}"; do
        if [[ $match =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            question="${BASH_REMATCH[3]}"
            eval "$variable=\"$default_value\""
            user_ask "$question" "$default_value" "$variable"
        fi
    done
}

get_latest_release(){
    local repo_owner=$1
    local repo_name=$2
    local url="https://api.github.com/repos/$repo_owner/$repo_name/releases/latest"
    local latest_version=$(curl -s -H 'Cache-Control: no-cache' $url | grep -oP '"tag_name": "\K(.*)(?=")')
    echo $latest_version
}

replace_string(){
    local old_string=$1
    local new_string=$2
    local file=$3
    sed -i "s|$old_string|$new_string|g" $file
}

mod_env_file() {
    local file=$1
    while read line; do
        if [[ $line =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            eval "replace_string \"\\[$variable\\]\" \$$variable $file" 
        fi
    done < $file
}

create_dirs(){
    local file=$1
    while read line; do
        if [[ $line =~ TN_DIR=\[(.*)\] ]]; then
            dir="${BASH_REMATCH[1]}"
            eval "mkdir -p $dir" 
        fi
    done < $file
}

copy_files(){
    local file=$1
    while read line; do
        if [[ $line =~ TN_FILE=\[([^|]*)\|([^|]*)\] ]]; then
            online="${BASH_REMATCH[1]}"
            local="${BASH_REMATCH[2]}"
            eval "curl -Ls -H 'Cache-Control: no-cache' 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/$online' -o $local"
        fi
        if [[ $line =~ TN_COPY=\[([^|]*)\|([^|]*)\] ]]; then
            online="${BASH_REMATCH[1]}"
            local="${BASH_REMATCH[2]}"
            eval "curl -Ls -H 'Cache-Control: no-cache' 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/$online' -o $local"
        fi
    done < $file
}

is_home_empty() {
  while true; do
    if [ ! -d "$DOCKER_HOME" ] || [ -z "$(ls -A $DOCKER_HOME)" ]; then
      break
    else
      user_ask "DOCKER HOME directory is not empty please select another one" "GENDIR" "DOCKER_HOME"
    fi
  done
}

create_neworks() {
    local file=$1
    local network_list=$(docker network ls --format "{{.Name}}")
    while read line; do
        if [[ $line =~ TN_NETWORK=\[(.*)\] ]]; then
            network_name="${BASH_REMATCH[1]}"
            if [[ $network_list =~ $network_name ]]; then
                echo "Network '$network_name' exists."
            else
                echo "Network '$network_name' does not exist. Creating it now..."
                docker network create $network_name
            fi
        fi
    done < $file
}

install_containers(){
    local file=$1
    while read line; do
        if [[ $line =~ TN_FILE=\[([^|]*)\|([^|]*)\] ]]; then
            online="${BASH_REMATCH[1]}"
            local="${BASH_REMATCH[2]}"
            if [[ "$local" =~ ^.*docker-compose.yml$ ]]; then
                if [ -s "$local" ]; then
                    parent_dir=$(dirname $local)
                    stack_name=$(basename $parent_dir)
                    eval "docker-compose -f $local --env-file $file down --volumes --remove-orphans"
                    eval "docker-compose -f $local --env-file $file up -d --force-recreate --build"                  
                fi
            fi
        fi
    done < $file
}

# FILES PATH
logfile="./install.log"
envfile="./.env"
tempfile="./.temp"

# CLEAR LOG FILE
if test -e $logfile; then
    rm $logfile
fi

# INSTALL DEPENDENCIES
if ! command -v curl > /dev/null 2>&1 || ! command -v id > /dev/null 2>&1 || ! command -v getent > /dev/null 2>&1; then
    (tnexec "apt-get update && apt-get install -y curl util-linux coreutils" $logfile) & spin "Installing script dependencies"
else
   sleep 0.1 & spin "Script dependencies already installed"
fi

# PARAMS
uname_s=$(uname -s)
uname_m=$(uname -m)
repo_owner="docker"
repo_name="compose"
latest_version=$(get_latest_release $repo_owner $repo_name)

# INSTALL FAIL2BAN
if ! command -v fail2ban-client -h > /dev/null 2>&1; then
   if user_confirm "Do you want to install fail2ban (some protection from ddos attack)"; then
        (tnexec "apt-get update && apt-get install -y fail2ban" $logfile) & spin "Installing fail2ban"
   fi
fi

# INSTALL UFW
if ! command -v ufw status verbose > /dev/null 2>&1; then
   if user_confirm "Do you want to install ufw (a basic firewall)"; then
        (tnexec "apt update && apt install -y ufw && ufw default deny incoming && ufw default allow outgoing && ufw allow 21,22,25,80,110,143,443,465,587,993,995,4190 && ufw enable" $logfile) & spin "Installing and configuring ufw"
   fi
fi

# INSTALL DOCKER
if ! command -v docker --version > /dev/null 2>&1; then
   install_docker $logfile
else
    if user_confirm "Docker is already installed, would you like a newer version"; then
        install_docker $logfile
    else
        sleep 0.1 & spin "$(docker --version) installed"
    fi
fi

# INSTALL DOCKER-COMPOSE
if ! command -v docker-compose --version > /dev/null 2>&1; then
   install_docker_compose $uname_s $uname_m $latest_version $logfile
else
    if user_confirm "Docker-compose is already installed, would you like a newer version"; then
        install_docker_compose $uname_s $uname_m $latest_version $logfile
    else
        sleep 0.1 & spin "$(docker-compose --version) installed"
    fi
fi

# CREATE DOCKER GROUP AND GET GID
if ! getent group docker > /dev/null 2>&1; then
    groupadd docker
fi
gid=$(getent group docker | cut -d: -f3)
sleep 0.1 & spin "Getting docker gid : $gid"

# CREATE DOCKER USER AND GET UID
if ! id -u docker > /dev/null 2>&1; then
    useradd -u $gid -g docker docker
fi
uid=$(id -u docker)
sleep 0.1 & spin "Getting docker uid : $uid"

# DOWNLOAD .env
(tnexec "curl -Ls -H 'Cache-Control: no-cache' 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/.env' -o $envfile" $logfile) & spin "Downloading .env file to config containers"

# REPLACE UID & GID
(tnexec "replace_string \"\\[UID\\]\" $uid $envfile" $logfile) & spin "Replacing docker uid($uid) in .env file"
(tnexec "replace_string \"\\[GID\\]\" $gid $envfile" $logfile) & spin "Replacing docker gid($gid) in .env file"

# ASK USER SOME QUESTIONS
ask_questions_from_file $envfile

# CHEK IF DOCKER HOME IS EMPTY (IF NOT ASK QUESTIONS AGAIN)
is_home_empty

# MODIFY .ENV FILE
(tnexec "mod_env_file $envfile" $logfile) & spin "Modifying .env file"

# CREATE PROJECT DIRECTORIES
(tnexec "rm $DOCKER_HOME -R" $logfile) & spin "Cleaning project directories"
(tnexec "create_dirs $envfile" $logfile) & spin "Creating project directories"

# COPY FILE FROM GITHUB TO PROJECT DIRECTORIES
(tnexec "copy_files $envfile" $logfile) & spin "Copying files from github to docker home"

# COPY .ENV TO DOCKER HOME DIRECTORIES
(tnexec "cp $envfile $DOCKER_HOME/.env" $logfile) & spin "Copy .env file to docker home"

# CREATE DOCKER NETWORKS
(tnexec "create_neworks $envfile" $logfile) & spin "Creating | checking docker networks"

# CHANGE OWNER OF DOCKER HOME
(tnexec "chown docker:docker $DOCKER_HOME -R" $logfile) & spin "Changing DOCKER HOME owner"

# INSTALL THE BASES CONTAINERS
(tnexec "install_containers $envfile" $logfile) & spin "Installing docker containers"

# CHANGE OWNER OF DOCKER HOME
(tnexec "chown docker:docker $DOCKER_HOME -R" $logfile) & spin "Changing DOCKER HOME owner"

# DOWNLOAD AND INSTALL USEFUL SCRIPT
tndockerfile="/usr/local/bin/tndocker"
(tnexec "curl -Ls -H 'Cache-Control: no-cache' 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/tndocker.sh' -o ./tndocker.sh" $logfile) & spin "Downloading tndocker.sh file"
(tnexec "replace_string \"\\[DOCKER_HOME\\]\" $DOCKER_HOME ./tndocker.sh" $logfile) & spin "Updating tndocker.sh"
(tnexec "mv ./tndocker.sh $tndockerfile && chmod +x $tndockerfile" $logfile) & spin "Copy tndocker.sh file to exe directory"

# DELETE ALL TEMPORARY FILES
#rm $envfile $logfile -R & spin "Cleaning installation files"

# DELETE THIS FILE