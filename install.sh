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
    (tnexec "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -f" $logfile) & spin "Downloading and saving docker key"
    (tnexec "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" $logfile) && spin "Modifying repositories source.list"
    (tnexec "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io" $logfile) & spin "Installing docker"
    sleep 0.1 & spin "$(docker --version) installed"
}

install_docker_compose(){
    local uname_s=$1
    local uname_m=$2
    local latest_version=$3
    local logfile=$4
    (tnexec "curl -L 'https://github.com/docker/compose/releases/download/$latest_version/docker-compose-$uname_s-$uname_m' -o /usr/local/bin/docker-compose" $logfile) & spin "Downloading docker-compose deb package"
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

user_ask() {
  local question=$1
  local default_value=$2
  local var=$3
  local yellow="\033[38;5;220m"
  local darker_yellow="\033[38;5;214m"
  local reset="\033[0m"
  echo -en "${yellow}? ${question} ${darker_yellow}(leave blank to use default ${default_value}) ${yellow}?${reset} "
  read answer
  if [[ "$answer" == "" ]]; then
    eval "$var=$default_value"
  else
    eval "$var=$answer"
  fi
}

get_latest_release(){
    local repo_owner=$1
    local repo_name=$2
    local url="https://api.github.com/repos/$repo_owner/$repo_name/releases/latest"
    local latest_version=$(curl -s $url | grep -oP '"tag_name": "\K(.*)(?=")')
    echo $latest_version
}

replace_string(){
    local old_string=$1
    local new_string=$2
    local file=$3
    sed -i "s/$old_string/$new_string/g" $file
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

# INSTALL DOCKER
if ! command -v docker --version > /dev/null 2>&1; then
   install_docker $logfile
else
    if user_confirm "Docker is already installed, would you like a newer version"; then
        install_docker $logfile
    else
        sleep 0.1 & spin "Docker already installed"
    fi
fi

# INSTALL DOCKER-COMPOSE
if ! command -v docker-compose --version > /dev/null 2>&1; then
   install_docker_compose $uname_s $uname_m $latest_version $logfile
else
    if user_confirm "Docker-compose is already installed, would you like a newer version"; then
        install_docker_compose $uname_s $uname_m $latest_version $logfile
    else
        sleep 0.1 & spin "Docker-compose already installed"
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
(tnexec "curl -Ls 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/.env' -o $envfile" $logfile) & spin "Downloading .env file to config containers"

# ASK USER SOME QUESTIONS AND MODIFY .env
docker_home="/home/docker" 
user_ask "Do you want to change docker home directory" $docker_home "docker_home"
sleep 0.1 & spin "Checking docker home directory : $docker_home"

# CREATE DOCKER DIRECTORIES

# INSTALL THE BASES CONTAINERS

# DELETE ALL TEMPORARY FILES

# DELETE THIS FILE
