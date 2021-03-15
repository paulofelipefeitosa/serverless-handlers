#!/bin/bash
set -e

ROUNDS=$1
FUNC_PROJ_PATH=$2
MAIN_FILEPATH=$3
LOG_FILEPATH=$4
RESULTS_FILEPATH=$5

set +e
bash clean.sh
set -e
bash launch.sh "$FUNC_PROJ_PATH" "$MAIN_FILEPATH" "$LOG_FILEPATH"
bash exec.sh "$ROUNDS" "$LOG_FILEPATH"
bash parse.sh "$LOG_FILEPATH" "$RESULTS_FILEPATH"