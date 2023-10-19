#!/bin/bash

# PARAMETERS
defaultColor="0"
blueColor="96"
darkBlueColor="36"
yellowColor="38;5;220"
darkYellowColor="38;5;214"
greenColor="38;5;47"
darkGreenColor="38;5;71"

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

tnIsUp2Date(){
    local package_name="$1"
    local installed_version=$(apt-cache policy $package_name | awk 'NR==2 {print $2}')
    local available_version=$(apt-cache policy $package_name | awk 'NR==3 {print $2}')
    if [ "$installed_version" != "$available_version" ]; then
        return 1
    else
        return 0
    fi
}

tnIsCommandMissing(){
    command -v $1 > /dev/null 2>&1 && return 1 || return 0
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

tnAreCommandsMissing(){
    local _commands=("$@")
    for value in "${_commands[@]}"; do
        if tnIsCommandMissing $value ;then
            return 0
        fi
    done
    return 1
}

tnSelect(){
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    tn_cursor_blink_on()   { printf "$ESC[?25h"; }
    tn_cursor_blink_off()  { printf "$ESC[?25l"; }
    tn_cursor_to()         { printf "$ESC[$1;${2:-1}H"; }
    tn_print_active()      { printf "$2 $1 $3"; }
    tn_get_cursor_row()    { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }

    local return_value=$1
    local -n options=$2
    local nb=${#3}
    nb=$(expr $nb + 4)
    if [[ $nb -lt 41 ]]; then
        nb=40
    fi
    tnDisplay "[-] ${3}\n" "$yellowColor"
    tnDisplay "[-] " "$yellowColor"
    tnDisplay "\"\u2191\"" "$darkYellowColor"
    #tnDisplay " and " "$yellowColor"
    tnDisplay " \"\u2193\"" "$darkYellowColor"
    tnDisplay " to move up and down the list\n" "$yellowColor"
    tnDisplay "[-] " "$yellowColor"
    tnDisplay "\"space bar\"" "$darkYellowColor"
    tnDisplay " to select option\n" "$yellowColor"
    tnDisplay "[-] " "$yellowColor"
    tnDisplay "\"enter\"" "$darkYellowColor"
    tnDisplay " to confirm your choices\n" "$yellowColor"
    tnDisplay "$(tnSep $nb)\n" "$yellowColor"

    local selected=()
    for ((i=0; i<${#options[@]}; i++)); do
        selected+=("false")
        printf "\n"
    done

    # determine current screen position for overwriting the options
    local lastrow=`tn_get_cursor_row`
    local startrow=$(($lastrow - ${#options[@]}))

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "tn_cursor_blink_on; stty echo; printf '\n'; exit" 2
    tn_cursor_blink_off

    tn_key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = ""      ]]; then echo enter; fi;
        if [[ $key = $'\x20' ]]; then echo space; fi;
        if [[ $key = "k" ]]; then echo up; fi;
        if [[ $key = "j" ]]; then echo down; fi;
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up;    fi;
            if [[ $key = [B || $key = j ]]; then echo down;  fi;
        fi 
    }

    tn_toggle_option() {
        local option=$1
        if [[ ${selected[option]} == true ]]; then
            selected[option]=false
        else
            selected[option]=true
        fi
    }

    tn_print_options() {
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
                prefix="[✔]"
            fi

            tn_cursor_to $(($startrow + $idx))
            if [ $idx -eq $active ]; then
                tnDisplay "  $prefix $option" "$greenColor"
            else
                tnDisplay "  $prefix $option" "$darkBlueColor"
            fi
            ((idx++))
        done
    }


    local active=0
    while true; do
        tn_print_options $active

        # user key control
        case `tn_key_input` in
            space)  tn_toggle_option $active;;
            enter)  tn_print_options -1; break;;
            up)     ((active--));
                    if [ $active -lt 0 ]; then active=$((${#options[@]} - 1)); fi;;
            down)   ((active++));
                    if [ $active -ge ${#options[@]} ]; then active=0; fi;;
        esac
    done

    # cursor position back to normal
    tn_cursor_to $lastrow
    printf "\n"
    tn_cursor_blink_on

    eval $return_value='("${selected[@]}")'
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
    local timestamp=$(date +%s)
    echo "/home/tndocker_$timestamp";
}

tnGenerateUuid(){
    local uuid=$(uuidgen)
    echo "$uuid"
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

tnDefaultValue(){
    local dv="$1"
    if [[ "$dv" == "GENPWD" ]]; then
        dv="$(tnGeneratePassword 10)"
    fi
    if [[ "$dv" == "GENDIR" ]]; then
        dv=$(date +%s)
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
    local file=$1
    local file2=$2
    local declare matches
    local variable_clean
    local variable_clean_name
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
            tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $file
            tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $file
            if [[ -n "$file2" ]]; then
                tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $file2
                tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $file2
            fi
        fi
    done
}

tnIsDirEmpty(){
    local dirpath=$1
    if [ ! -d "$dirpath" ] || [ -z "$(ls -A $dirpath)" ]; then
      return 0
    else
      return 1
    fi
}

tnIsHomeEmpty() {
    while true; do
        if tnIsDirEmpty "$DOCKER_HOME"; then
            break
        else
            tnAskUser "$DOCKER_HOME directory is not empty please select another one" "GENDIR" "DOCKER_HOME"
        fi
    done
}

tnDownload(){
    if [ "$3" == "dev" ]; then
        cp $1 $2
    else
        curl -Ls -H 'Cache-Control: no-cache' "$1" -o "$2" 
    fi
}

tnReplaceStringInFile(){
  sed -i "s|$1|$2|g" $3
}

tnAutoFromFile() {
    local file=$1
    local file2=$2
    local declare matches
    local variable_clean
    local variable_clean_name
    while read line; do
        if [[ $line =~ TN_AUTO=\[([^|]*)\|([^|]*)\|([^|]*)\] ]]; then
            matches+=("$line")
        fi
    done < $file
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
            tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $file
            tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $file
            if [[ -n "$file2" ]]; then
                tnReplaceStringInFile "\\[$variable\\]" "${!variable}" $file2
                tnReplaceStringInFile "\\[$variable_clean_name\\]" "$variable_clean" $file2
            fi
        fi
    done
}

tnCreateNetworkFromFile() {
    local file=$1
    while read line; do
        if [[ $line =~ TN_NETWORK=\[(.*)\] ]]; then
            network="${BASH_REMATCH[1]}"
            printf "docker network create -d bridge $network \n"
            docker network create -d bridge $network
        fi
    done < $file
}

tnCreateDirFromFile(){
    local file=$1
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
    sleep 0.1 & spin "$(docker --version) installed"
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