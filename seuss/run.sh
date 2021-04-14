#!/bin/bash
set -e

EXP_ID=$1
ROUNDS=$2
FUNC_PROJ_PATH=$3
MAIN_FILEPATH=$4
LOG_FILEPATH=$5
RESULTS_FILEPATH=$6

set +e
bash clean.sh "$LOG_FILEPATH"

bash launch.sh "$FUNC_PROJ_PATH" "$MAIN_FILEPATH" "$LOG_FILEPATH"
exit_status=$?
if [ "$exit_status" != 0 ];
then
  echo "Unable to launch SEUSS, exiting with status 10"
  exit 10
fi

bash exec.sh "$ROUNDS" "$LOG_FILEPATH"
exit_status=$?
if [ "$exit_status" != 0 ];
then
  echo "Unable to execute function, exiting with status 11"
  exit 11
fi

set -e
bash parse.sh "$EXP_ID" "$LOG_FILEPATH" "$RESULTS_FILEPATH"