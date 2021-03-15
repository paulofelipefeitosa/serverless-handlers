#!/bin/bash
set -e

LOGS_PATH=${PWD}/logs
CONF_PATH=${PWD}/conf
FUNC_PROJ_PATH=$1
MAIN_FILEPATH=$2
LOG_FILEPATH=$3

if [[ ! -d "$FUNC_PROJ_PATH" ]]
then
  echo "$FUNC_PROJ_PATH is not a directory, please set the correct function project directory path"
  exit 1
fi

echo "Launching SEUSS"

cd tasks/
ansible-playbook --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 deploy.yml -i ansible_hosts \
  --extra-vars "logs_path=$LOGS_PATH conf_path=$CONF_PATH function_project=$FUNC_PROJ_PATH main_file=$MAIN_FILEPATH"
cd ..

echo "Waiting until SEUSS native container be up and running"

while
  docker logs mycontainer &> "$LOG_FILEPATH"
  if grep -q "ALLOCATION TIME: " "$LOG_FILEPATH";
  then
    break
  else
    sleep 1
  fi
do
  :
done

echo "Done"
