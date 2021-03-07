#!/bin/bash
set -e

LOGS_PATH=${PWD}/logs
CONF_PATH=${PWD}/conf
FUNC_PROJ_PATH=$1
MAIN_FILE=$2

if [[ ! -d "$FUNC_PROJ_PATH" ]]
then
  echo "$FUNC_PROJ_PATH is not a directory, please set the correct function project directory path"
  exit 1
fi

if [[ ! -f "$MAIN_FILE" ]]
then
  echo "$MAIN_FILE is not a file, please set the correct executable function filepath"
fi

cd tasks/
ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 deploy.yml -i ansible_hosts \
  --extra-vars "logs_path=$LOGS_PATH conf_path=$CONF_PATH function_project=$FUNC_PROJ_PATH main_file=$MAIN_FILE"
cd ..

sleep 10

docker logs mycontainer