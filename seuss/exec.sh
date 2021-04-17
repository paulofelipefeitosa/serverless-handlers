#!/bin/bash
set -e

ROUNDS=$1
LOG_FILEPATH=$2

echo "Executing experiment with the following parameters: ($ROUNDS, 1, 1, 1)"

PID=$(docker inspect -f '{{.State.Pid}}' mycontainer)
echo "Writing on PID: $PID"
docker exec -it mycontainer sh -c "echo $ROUNDS, 1, 1, 1 > /proc/$PID/fd/0"

sleep 1

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