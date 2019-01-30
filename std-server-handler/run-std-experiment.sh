#!/bin/bash
set -e
APP=$1
JAR_PATH=$2
echo "Building $APP App to Jar [$JAR_PATH]"
cd $APP && mvn install
cd -

echo "Building experiment"
go build execute-std-requests.go

echo "Starting experiment"

IMAGE_URL=$3
IMAGE_NAME=$(basename $IMAGE_URL)
wget -O $IMAGE_NAME $IMAGE_URL
IMAGE_PATH=$(pwd)/$IMAGE_NAME

REP=$4

RESULTS_FILENAME=std-server-handler-$APP-"$(date +%s)"-"$REP".csv

echo "Number of executions [$REP]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,Id,Value" > $RESULTS_FILENAME

for i in $(seq "$REP")
do
	echo "Rep $i..."
	scale=0.1 image_path=$IMAGE_PATH ./execute-std-requests $REP $JAR_PATH >> $RESULTS_FILENAME
done