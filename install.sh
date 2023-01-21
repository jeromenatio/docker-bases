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
    local command="$1"
    eval "$command" >> "$logfile" 2>&1
}

install_docker(){
    (tnexec "apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg lsb-release") & spin "Installing docker dependencies"
    (tnexec "curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -f") & spin "Downloading and saving docker key"
    (tnexec "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null") && spin "Modifying repositories source.list"
    (tnexec "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io") & spin "Installing docker"
    sleep 0.1 & spin "$(docker --version) installed"
}

install_docker_compose(){
    (tnexec "curl -L 'https://github.com/docker/compose/releases/download/$latest_version/docker-compose-$uname_s-$uname_m' -o /usr/local/bin/docker-compose") & spin "Downloading docker-compose deb package"
    (tnexec "chmod +x /usr/local/bin/docker-compose") & spin "Installing docker-compose"
    sleep 0.1 & spin "$(docker-compose --version) installed"
}

user_confirm() {
  local question="$1"
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

get_latest_release() {
    repo_owner=$1
    repo_name=$2
    url="https://api.github.com/repos/$repo_owner/$repo_name/releases/latest"
    latest_version=$(curl -s $url | grep -oP '"tag_name": "\K(.*)(?=")')
    echo $latest_version
}

# FILES PATH
logfile="./install.log"
envfile="./.env"

# CLEAR LOG FILE
if test -e $logfile; then
    rm $logfile
fi

# INSTALL DEPENDENCIES
if ! command -v curl > /dev/null 2>&1 || ! command -v id > /dev/null 2>&1 || ! command -v getent > /dev/null 2>&1; then
    (tnexec "apt-get update && apt-get install -y curl util-linux coreutils") & spin "Installing script dependencies"
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
   install_docker
else
    if user_confirm "Docker is already installed, would you like a newer version"; then
        install_docker
    else
        sleep 0.1 & spin "Docker already installed"
    fi
fi

# INSTALL DOCKER-COMPOSE
if ! command -v docker-compose --version > /dev/null 2>&1; then
   install_docker_compose
else
    if user_confirm "Docker-compose is already installed, would you like a newer version"; then
        install_docker_compose
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
    useradd -g docker docker
fi
uid=$(id -u docker)
sleep 0.1 & spin "Getting docker uid : $uid"

# DOWNLOAD .env
(tnexec "curl -L 'https://raw.githubusercontent.com/jeromenatio/docker-bases/main/.env' -o $envfile") & spin "Downloading .env file to config containers"

# ASK USER SOME QUESTIONS AND MODIFY .env

# CREATE DOCKER DIRECTORIES

# INSTALL THE BASES CONTAINERS

# DELETE ALL TEMPORARY FILES

# DELETE THIS FILE

# https://raw.githubusercontent.com/jeromenatio/docker-bases/main/nginxproxy.yml
