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

# DON'T FORGET ITS FOR DEBIAN ONLY

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

tnIsMultiInstance(){
    local file=$1
    local answer="false"
    while read line; do
        if [[ $line =~ TN_MULTI=\[(.*)\] ]]; then            
            answer="${BASH_REMATCH[1]}"
        fi
    done < $file
    if [ "$answer" == "true" ]; then
        return 0
    else
        return 1
    fi
}

tnGetInstancePathFromFile(){
    local file=$1
    local answer="false"
    while read line; do
        if [[ $line =~ TN_BASEDIR=\[(.*)\] ]]; then            
            answer="${BASH_REMATCH[1]}"
        fi
    done < $file
    echo "$answer"
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

tnBase64Encode(){
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'
}

tnJson(){
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | jq -c .
}

tnHmacha256Sign(){
	local secret="$2"
	declare input=${1:-$(</dev/stdin)}
	printf '%s' "${input}" | openssl dgst -binary -sha256 -hmac "${secret}"
}

tnGenerateJWTSecret() {
    cat /dev/urandom | tr -dc 'a-z0-9' | head -c 40
}

tnGenerateJWTKey(){
	local secret="$1"
	local payload="$2"
	local header='{"alg":"HS256","typ":"JWT"}'
	header_base64=$(echo "${header}" | tnJson | tnBase64Encode)
	payload_base64=$(echo "${payload}" | tnJson | tnBase64Encode)
	header_payload=$(echo "${header_base64}.${payload_base64}")
	signature=$(echo "${header_payload}")
	signature=$(tnHmacha256Sign "$signature" "$secret")
	signature=$(tnBase64Encode "$signature")
	echo "${header_payload}.${signature}"
}

tnGenerateUuid(){
    local uuid=$(uuidgen)
    echo "$uuid"
}

tnDefaultValue(){
    local dv="$1"
    local varsFile="$2"
    local extra="$3"
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
    if [[ "$dv" == "JWTSECRET" ]]; then
        dv=$(tnGenerateJWTSecret)
    fi
    if [[ "$dv" == "JWTKEY" ]]; then
        JWT_SECRET=""
        while read line; do
            name=$(echo "$line" | sed -n 's/^\([^=]*\)=\[\(.*\)\]$/\1/p')
            data=$(echo "$line" | sed -n 's/^\([^=]*\)=\[\(.*\)\]$/\2/p')
            if [[ "$name" == "JWT_SECRET" ]]; then
                JWT_SECRET="$data"
            fi
        done < "$varsFile"
        dv=$(tnGenerateJWTKey $JWT_SECRET $extra)
    fi
    if [[ "$dv" == "RANDOMHASH"  ]]; then
        dv=$(openssl rand -base64 48)
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
    if [[ "$dv" == "RANDOMHASH" ]]; then
        dp="leave blank to generate random hash"
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

tnSetDockerHome(){
  local question="Please specify DOCKER_HOME directory"
  local variable="DOCKER_HOME"
  local default_display="This is mandatory"
  tnDisplay "? $question" "$yellowColor"
  tnDisplay " ($default_display)" "$darkYellowColor"
  tnDisplay " ? " "$yellowColor"
  read answer
  if [[ "$answer" == "" ]]; then
    tnSetDockerHome
  else
    eval "$variable=\"$answer\""
  fi
}

tnAskUser() {
    local question="$1"
    local default_value="$2"
    local variable="$3"
    local varsFile="$4"
    local extra="$5"
    local default_display="leave blank to use default $default_value"
    local save_default_value=$default_value
    default_value=$(tnDefaultValue "$default_value" "$varsFile" $extra)
    default_display=$(tnDefaultDisplay "$save_default_value" "$default_display")
    tnDisplay "? $question" "$yellowColor"
    tnDisplay " ($default_display)" "$darkYellowColor"
    tnDisplay " ? " "$yellowColor"
    read answer
    if [[ "$answer" == "" ]]; then
        answer="$default_value"
    fi
    if [[ "$answer" == "" ]]; then
        tnAskUser "$question" "$save_default_value" "$variable" "$varsFile" "$extra"
    else
        echo "$variable=[$answer]" >> $varsFile
    fi
}

tnAskUserFromFile() {
    local envFile="$1"
    local varsFile="$2"
    local declare matches
    while read line; do
        if [[ $line =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\] || $line =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < "$envFile"
    for match in "${matches[@]}"; do
        if [[ $match =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\] || $match =~ TN_ASK=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            question="${BASH_REMATCH[3]}"
            extra="${BASH_REMATCH[4]}"
            tnAskUser "$question" "$default_value" "$variable" "$varsFile" $extra
        fi
    done
}

tnAutoVarsFromFile() {
    local envFile="$1"    
    local varsFile="$2"
    local declare matches
    while read line; do
        if [[ $line =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\] || $line =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < "$envFile"
    for match in "${matches[@]}"; do
        if [[ $match =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)\] || $match =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            variable="${BASH_REMATCH[1]}"
            default_value="${BASH_REMATCH[2]}"
            extra="${BASH_REMATCH[4]}"
            default_value=$(tnDefaultValue "$default_value" "$varsFile" $extra)
            echo "$variable=[$default_value]" >> $varsFile
        fi
    done
}

tnCreateNetworksFromFile() {
    local file="$1"
    while read line; do
        if [[ $line =~ TN_NETWORK=\[(.*)\] ]]; then
            network="${BASH_REMATCH[1]}"
            printf "docker network create -d bridge $network \n"
            docker network create -d bridge $network
        fi
    done < $file
}

tnCreateDirsFromFile(){
    local file="$1"
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

tnSetStamps() {
  local file="$1"
  
  # Extract patterns from the file
  pattern_occurrences=$(grep -oE '\[DATE[+-][0-9]+[a-zA-Z]+\]' "$file")

  # Loop through each pattern
  for occurrence in $pattern_occurrences; do
    sign=$(echo "$occurrence" | sed -E 's/\[DATE([+-])[0-9]+[a-zA-Z]+\]/\1/')
    number=$(echo "$occurrence" | sed -E 's/\[DATE[+-]([0-9]+)[a-zA-Z]+\]/\1/')
    unit=$(echo "$occurrence" | sed -E 's/\[DATE[+-][0-9]+([a-zA-Z]+)\]/\1/')
    
    # Output the found pattern and extracted values for debugging
    #echo "Found Pattern: $occurrence, Sign: $sign, Number: $number, Unit: $unit"
    
    # Calculate total seconds
    total_seconds=$(tnCalculateSeconds "$number" "$unit")

    # Calculate actual timestamp
    timestamp=$(tnCalculateTimestamp "$sign" "$total_seconds")

    # Replace the pattern with the calculated timestamp
    sed -i -E "s|\[DATE${sign//+/\\+}$number$unit\]|$timestamp|g" "$file"
  done
}

tnCalculateSeconds() {
  local number=$1
  local unit=$2
  local total_seconds=0

  case $unit in
    "seconds")
      total_seconds=$number
      ;;
    "minutes")
      total_seconds=$((number * 60))
      ;;
    "hours")
      total_seconds=$((number * 3600))
      ;;
    "days")
      total_seconds=$((number * 24 * 3600))
      ;;
    "months")
      total_seconds=$((number * 30 * 24 * 3600))
      ;;
    "years")
      total_seconds=$((number * 365 * 24 * 3600))
      ;;
    *)
      echo "Invalid unit: $unit"
      exit 1
      ;;
  esac

  echo "$total_seconds"
}

tnCalculateTimestamp() {
  local sign=$1
  local total_seconds=$2
  local current_timestamp=$(date +%s)
  local result_timestamp=0

  if [ "$sign" = "+" ]; then
    result_timestamp=$((current_timestamp + total_seconds))
  elif [ "$sign" = "-" ]; then
    result_timestamp=$((current_timestamp - total_seconds))
  else
    echo "Invalid sign: $sign"
    exit 1
  fi

  echo "$result_timestamp"
}

tnSetVars(){
    local file="$1"
    local varsFile="$2"
    local declare matches
    while read line; do
        name=$(echo "$line" | sed -n 's/^\([^=]*\)=\[\(.*\)\]$/\1/p')
        data=$(echo "$line" | sed -n 's/^\([^=]*\)=\[\(.*\)\]$/\2/p')
        tnReplaceVarInFile "$name" "$data" "$file"
    done < "$varsFile"
}

tnReplaceVarInFile(){
    local name="$1"
    local data="$2"
    local file="$3"
    local tstr="_CLEAN"
    local name_clean="$name$tstr"
    local data_clean="$data"
    data_clean="${data_clean//./-}"
    tnReplaceStringInFile "\\[$name\\]" "$data" $file
    tnReplaceStringInFile "\\[$name_clean\\]" "$data_clean" $file
    #echo "----------------"
    #echo "\\[$name\\] => $data => $file"
    #echo "\\[$name_clean\\] => $data_clean => $file"
    #echo "----------------"
}

tnSetGlobals(){
    local file="$1"
    (tnExec "tnReplaceStringInFile '\\[DOCKER_HOME\\]' '$DOCKER_HOME' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[UTILS_FILES\\]' '$UTILS_FILE' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[GITHUB\\]' '$GITHUB' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[LOG_FILE\\]' '$LOG_FILE' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[_UID\\]' '$_UID' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[_GID\\]' '$_GID' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[UID\\]' '$_UID' '$file'" $LOG_FILE)
    (tnExec "tnReplaceStringInFile '\\[GID\\]' '$_GID' '$file'" $LOG_FILE)
}

tnDownloadAndSetAllFiles(){
    local envFile="$1"
    local disDir="$2"
    local varsFile="$3"
    local declare files
    local instance=$(tnGetInstancePathFromFile $envFile)

    # Docker Compose file
    local dis="$disDir/docker-compose.yml"
    local loc="$instance/docker-compose.yml"
    tnDownload $dis $loc
    tnSetStamps $loc
    tnSetGlobals $loc
    tnSetVars $loc $varsFile
    
    # Every other files
    while read line; do
        if [[ $line =~ TN_FILE=\[(.*)\] ]]; then
            files+=("$line")
        fi
    done < "$envFile"
    for match_file in "${files[@]}"; do
        if [[ $match_file =~ TN_FILE=\[(.*)\] ]]; then
            matched="${BASH_REMATCH[1]}"
            dis="$disDir/$matched"
            loc="$instance/$matched"
            tnDownload $dis $loc
            tnSetStamps $loc
            tnSetGlobals $loc
            tnSetVars $loc $varsFile
        fi
    done
}

# ALWAYS LEAVE BLANK LINE AT THE END
