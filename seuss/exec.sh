#!/bin/bash
set -e

ROUNDS=$1
LOG_FILEPATH=$2

echo "Executing experiment with the following parameters: ($ROUNDS, 1, 1, 1)"

echo "$ROUNDS, 1, 1, 1" | docker attach mycontainer &

sleep 1

lines=$((2 * "$ROUNDS"))

while
  docker logs mycontainer &> "$LOG_FILEPATH"
  # shellcheck disable=SC2126
  len=$(grep -A1 "Scheduling activation" < "$LOG_FILEPATH" | wc -l)
  if [ "$len" == "$lines" ];
  then
    break
  else
    sleep 1
  fi
do
  :
done

echo "End of the experiment"