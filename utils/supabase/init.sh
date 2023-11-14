#!/bin/bash

# LOCAL PARAMS
ENV="dev"
BASE_DEFAULT="/home/jwt"
$GITHUB="https://raw.githubusercontent.com/jeromenatio/docker-bases/main"
[ "$ENV" == "dev" ] && eval "rm ${BASE_DEFAULT}* -R > /dev/null 2>&1" > /dev/null 2>&1

# EXTERNAL PARAMS
DIRPATH="${1:-$BASE_DEFAULT}"

# INSTALL NODEJS AND NPM
[ "$ENV" != "dev" ] && apt-get update > /dev/null 2>&1 && apt-get install -y nodejs npm > /dev/null 2>&1

# CREATE TEMPORARY DIRECTORIES AND BASICS FILES
mkdir "$DIRPATH" > /dev/null 2>&1

# NPM INIT DIRECTORY AND INSTALL PACKAGE `jsrsasign`
(cd "$DIRPATH" && npm init -y > /dev/null 2>&1)
(cd "$DIRPATH" && npm install jsrsasign -y > /dev/null 2>&1)

# DOWNLOAD jwt.mjs
curl -Ls -H 'Cache-Control: no-cache' "$GITHUB/utils/jwt.mjs" -o "$DIRPATH/jwt.mjs" > /dev/null 2>&1