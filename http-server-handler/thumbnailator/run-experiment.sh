#!/bin/bash
set -e
echo "Building App"
mvn install
go build execute-requests.go

echo "Starting experiment"

REP=$1
RESULTS_FILENAME=http-server-handler-exp-"$(date +%s)"-"$REP".csv

echo "Number of executions [$REP]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,Id,Value" > $RESULTS_FILENAME

for i in $(seq "$REP")
do
	echo "Rep $i..."
	scale=0.1 image_url=https://i.imgur.com/BhlDUOR.jpg ./execute-requests localhost:9000 / $REP $i >> $RESULTS_FILENAME
done