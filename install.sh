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
  local spin_color=96
  local text_color=36
  while kill -0 $pid 2>/dev/null
  do
    i=$(( (i+1) %10 ))
    printf "\033[${text_color}m\r\033[${spin_color}m${spin:$i:1} \033[${text_color}m$text\033[0m"
    sleep .1
  done
  printf "\033[${spin_color}m\r$check_character $text\033[0m\n"
}

# PARAMS
sleep 10 & spin "Waiting in vain"

# INSTALL DEPENDENCIES

# INSTALL DOCKER

# CREATE DOCKER USER AND GROUP

# DOWNLOAD .env

# ASK USER SOME QUESTIONS AND MODIFY .env

# CREATE DOCKER DIRECTORIES

# INSTALL THE BASES CONTAINERS

# DELETE ALL TEMPORARY FILES

# DELETE THIS FILE

# https://raw.githubusercontent.com/jeromenatio/docker-bases/main/nginxproxy.yml
