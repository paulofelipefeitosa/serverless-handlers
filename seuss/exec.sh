#!/bin/bash
set -e

ROUNDS=$1

echo "Executing experiment with the following parameters: ($ROUNDS, 1, 1, 1)"

echo "$ROUNDS, 1, 1, 1" | docker attach mycontainer &

ATTACH_PID=$!
lines=$((2 * "$ROUNDS"))

while
  docker logs mycontainer &> mycontainer.log
  # shellcheck disable=SC2126
  len=$(grep -A1 "Scheduling activation" < mycontainer.log | wc -l)
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