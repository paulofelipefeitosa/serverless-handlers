#!/bin/bash
set -e

ROUNDS=$1
LOG_FILEPATH=$2

echo "Executing experiment with the following parameters: ($ROUNDS, 1, 1, 1)"

echo "$ROUNDS, 1, 1, 1" | docker attach mycontainer &

sleep 3

lines=$((2 * "$ROUNDS"))
max_retries=100
count=0

while
  docker logs mycontainer &> "$LOG_FILEPATH"
  # shellcheck disable=SC2126
  len=$(grep -A1 "Scheduling activation tid" < "$LOG_FILEPATH" | wc -l)
  if [ "$len" -ge "$lines" ];
  then
    break
  elif [ "$count" -ge "$max_retries" ];
  then
    echo "Max retries reached, exiting with status 10"
    exit 10
  else
    count=$((count + 1))
    sleep 1
  fi
do
  :
done

echo "End of the experiment"