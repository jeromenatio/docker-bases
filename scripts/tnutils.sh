#!/bin/bash

# PARAMETERS
defaultColor="0"
blueColor="96"
darkBlueColor="36"
yellowColor="38;5;220"
darkYellowColor="38;5;214"
greenColor="38;5;47"
darkGreenColor="38;5;71"
darkRedColor="38;5;124"

# FUNCTIONS
tnDisplay(){
    printf "\033[${2}m${1}\033[${defaultColor}m"
}

tnSep(){
    result=""
    for ((i=0; i<$1; i++)); do
        result+="-"
    done
    echo $result
}

tnExec() {
    eval "$1" >> "$2" 2>&1
}

tnSpin() {
  local pid=$!
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %10 ))
    tnDisplay "\r${spin:$i:1} $1" "$blueColor"
    sleep .1
  done
  tnDisplay "\r✔ $1\n" "$darkBlueColor"
}

tnIsDirEmpty(){
    local dirpath=$1
    if [ ! -d "$dirpath" ] || [ -z "$(ls -A $dirpath)" ]; then
      return 0
    else
      return 1
    fi
}

tnIsCommandMissing(){
    command -v $1 > /dev/null 2>&1 && return 1 || return 0
}

tnAreCommandsMissing(){
    local _commands=("$@")
    for value in "${_commands[@]}"; do
        if tnIsCommandMissing $value ;then
            return 0
        fi
    done
    return 1
}

tnGeneratePassword() {
    local LENGTH=$1
    local LOWERCASE_CHARS=(a b c d e f g h j k m n p q r s t u v w x y z)
    local UPPERCASE_CHARS=(A B C D E F G H J K M N P Q R S T U V W X Y Z)
    local NUMBER_CHARS=(0 1 2 3 4 5 6 7 8 9)
    local SPECIAL_CHARS=("!" "*")
    local PASSWORD=""
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

tnGenerateDir(){
    timestamp=$(date +%s)
    echo "$timestamp";
}

tnGenerateUuid(){
    local uuid=$(uuidgen)
    echo "$uuid"
}

tnDefaultValue(){
    local dv="$1"
    if [[ "$dv" == "GENPWD" ]]; then
        dv="$(tnGeneratePassword 10)"
    fi
    if [[ "$dv" == "GENDIR" ]]; then
        dv=$(tnGenerateDir)
    fi
    if [[ "$dv" == "UUID" ]]; then
        dv="$(tnGenerateUuid)"
    fi
    if [[ "$dv" == "GENINSTANCE" ]]; then
        dv=$(date +%s)
    fi
    if [[ "$dv" == "MANDATORY" ]]; then
        dv=""
    fi
    echo $dv
}

tnDefaultDisplay(){
    local dv="$1"
    local dp="$2"
    if [[ "$dv" == "GENPWD" ]]; then
        dp="leave blank to generate random password"
    fi
    if [[ "$dv" == "GENDIR" ]]; then
        dp="leave blank to generate random dir path"
    fi
    if [[ "$dv" == "UUID" ]]; then
        dp="leave blank to generate random uuid"
    fi
    if [[ "$dv" == "GENINSTANCE" ]]; then
        dp="leave blank to generate random instance name"
    fi
    if [[ "$dv" == "MANDATORY" ]]; then
        dp="This answer is mandatory and must be unique"
    fi
    echo $dp
}

tnDownload(){
    if [ "$ENV" == "dev" ]; then
        cp $1 $2
    else
        curl -Ls -H 'Cache-Control: no-cache' "$1" -o "$2" 
    fi
}

tnReplaceStringInFile(){
  sed -i "s|$1|$2|g" $3
}

tnUserConfirm() {
  local question=$1
  echo -en "${yellowColor}? ${question} ${darkYellowColor}(y/n) ${yellowColor}?${defaultColor} "
  read answer
  if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
    return 0 
  else
    return 1
  fi
}

tnAskUser() {
  local question="$1"
  local default_value="$2"
  local variable="$3"
  local default_display="leave blank to use default $default_value"
  local save_default_value=$default_value
  default_value=$(tnDefaultValue "$default_value")
  default_display=$(tnDefaultDisplay "$save_default_value" "$default_display")
  tnDisplay "? $question" "$yellowColor"
  tnDisplay " ($default_display)" "$darkYellowColor"
  tnDisplay " ? " "$yellowColor"
  read answer
  if [[ "$answer" == "" ]]; then
    eval "$variable=\"$default_value\""
  else
    eval "$variable=\"$answer\""
  fi
}

tnAskUserFromFile() {
    local _dir="$1" 
    local envFile="$_dir/.env"
    local composeFile="$_dir/docker-compose.yml"
    local declare matches
    local variable_clean
    local variable_clean_name
    local declare files
    while read line; do
        if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
            files+=("$line")
        fi
    done < $envFile
    while read line; do
        if [[ $line =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < $envFile
    for match in "${matches[@]}"; do
        if [[ $match =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            question="${BASH_REMATCH[3]}"
            eval "$variable=\"$default_value\""
            tnAskUser "$question" "$default_value" "$variable"
            while true; do
                if [ "${!variable}" == "" ]; then
                    tnAskUser "$question" "$default_value" "$variable"
                else
                    break
                fi
            done

            # XXXXX
            tempstr="_CLEAN"
            variable_clean_name="$variable$tempstr"           
            variable_clean="${!variable}"
            variable_clean="${variable_clean//./-}" 
            tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $envFile
            tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $envFile
            if [ "$DOCKER_HOME" != "$_dir" ]; then
                tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $composeFile
                tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $composeFile
            fi
            for match_file in "${files[@]}"; do
                if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
                    matched="${BASH_REMATCH[1]}"
                    tnReplaceStringInFile "\\[$variable\\]" "${!variable}" "$_dir/$matched"
                    tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" "$_dir/$matched"
                fi
            done
        fi
    done
}

tnAutoFromFile() {
    local _dir="$1" 
    local envFile="$_dir/.env"
    local composeFile="$_dir/docker-compose.yml"
    local declare matches
    local variable_clean
    local variable_clean_name
    local declare files
    while read line; do
        if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
            files+=("$line")
        fi
    done < $envFile
    while read line; do
        if [[ $line =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < $envFile
    for match in "${matches[@]}"; do
        if [[ $match =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            default_value=$(tnDefaultValue "$default_value")
            question="${BASH_REMATCH[3]}"
            eval "$variable=\"$default_value\""

            # XXXXX
            tempstr="_CLEAN"
            variable_clean_name="$variable$tempstr"
            variable_clean="${!variable}"
            variable_clean="${variable_clean//./-}"
            tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $envFile
            tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $envFile
            if [ "$DOCKER_HOME" != "$_dir" ]; then
                tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $composeFile
                tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $composeFile 
            fi                   
            for match_file in "${files[@]}"; do
                if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
                    matched="${BASH_REMATCH[1]}"
                    tnReplaceStringInFile "\\[$variable\\]" "${!variable}" "$_dir/$matched"
                    tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" "$_dir/$matched"
                fi
            done
        fi
    done
} 

tnDownloadFromFile(){
    local dis="$1"
    local loc="$2"
    local declare files
    curl -Ls -H 'Cache-Control: no-cache' "$dis/.env" -o "$loc/.env"
    if [ "$DOCKER_HOME" != "$loc" ]; then
        curl -Ls -H 'Cache-Control: no-cache' "$dis/docker-compose.yml" -o "$loc/docker-compose.yml"  
    fi
    while read line; do
        if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
            files+=("$line")
        fi
    done < "$loc/.env"
    for file in "${files[@]}"; do
        file="${BASH_REMATCH[1]}"
        curl -Ls -H 'Cache-Control: no-cache' "$dis/$file" -o "$loc/$file" 
    done
}

tnCreateNetworkFromFile() {
    local file="$1/.env"
    while read line; do
        if [[ $line =~ TN_NETWORK=\[(.*)\] ]]; then
            network="${BASH_REMATCH[1]}"
            printf "docker network create -d bridge $network \n"
            docker network create -d bridge $network
        fi
    done < $file
}

tnCreateDirFromFile(){
    local file="$1/.env"
    while read line; do
        if [[ $line =~ TN_DIR=\[(.*)\] ]]; then
            dir="${BASH_REMATCH[1]}"
            eval "mkdir -p $dir" 
        fi
    done < $file
}

tnInstallDocker(){
    local logfile=$1
    (tnExec "apt-get update && apt-get install -y apt-transport-https ca-certificates gnupg lsb-release" $logfile) & tnSpin "Installing docker dependencies"
    if [[ ! -e "/usr/share/keyrings/docker-archive-keyring.gpg" ]]; then
        (tnExec "curl -fsSL -H 'Cache-Control: no-cache' https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" $logfile) & tnSpin "Downloading and saving docker key"
    fi
    (tnExec "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable' | tee /etc/apt/sources.list.d/docker.list > /dev/null" $logfile) & tnSpin "Modifying repositories source.list"
    (tnExec "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io" $logfile) & tnSpin "Installing docker"
    sleep 0.1 & tnSpin "$(docker --version) installed"
}

tnInstallDockerCompose(){
    local uname_s=$1
    local uname_m=$2
    local latest_version=$3
    local logfile=$4
    (tnExec "curl -Ls -H 'Cache-Control: no-cache' 'https://github.com/docker/compose/releases/download/$latest_version/docker-compose-$uname_s-$uname_m' -o /usr/local/bin/docker-compose" $logfile) & tnSpin "Downloading docker-compose deb package"
    (tnExec "chmod +x /usr/local/bin/docker-compose" $logfile) & tnSpin "Installing docker-compose"
    sleep 0.1 & tnSpin "$(docker-compose --version) installed"
}

tnGetLatestRelease(){
    local repo_owner=$1
    local repo_name=$2
    local url="https://api.github.com/repos/$repo_owner/$repo_name/releases/latest"
    local latest_version=$(curl -s -H 'Cache-Control: no-cache' $url | grep -oP '"tag_name": "\K(.*)(?=")')
    echo $latest_version
}