#!/bin/bash
set -e

EXP=$1
ROUNDS=$2
FUNC_PROJ_PATH=$3
MAIN_FILEPATH=$4
LOG_FILEPATH=$5
RESULTS_FILEPATH=$6

echo "exp_id, req_id, duration, start_ts, end_ts, status, wait_time, init_time, run_time, resp" > "$RESULTS_FILEPATH"

for exp in $(seq "$EXP")
do
  echo "Executing experiment: $exp"
  set +e
  bash run.sh "$exp" "$ROUNDS" "$FUNC_PROJ_PATH" "$MAIN_FILEPATH" "$LOG_FILEPATH" "$RESULTS_FILEPATH"
  set -e
  echo "Finishing experiment: $exp"
done