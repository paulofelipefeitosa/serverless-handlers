#!/bin/bash
set -e
TYPE_DIR=$1 # server-http-handler or std-server-handler
APP_NAME=$2 # APP DIR NAME
JAR_NAME=$3 # JAR NAME
IMAGE_URL=$4
REP=$5

APP_DIR=$TYPE_DIR/$APP_NAME
JAR_PATH=$APP_DIR/target/$JAR_NAME

echo "Building $APP_DIR App to Jar [$JAR_PATH]"
cd $APP_DIR && mvn install
cd -

echo "Building experiment"
EXP_APP_NAME="execute-requests"
go build $TYPE_DIR/"$EXP_APP_NAME".go

echo "Downloading image from [$IMAGE_URL]"
IMAGE_NAME=$(basename $IMAGE_URL)
wget -O $IMAGE_NAME $IMAGE_URL
IMAGE_PATH=$(pwd)/$IMAGE_NAME

echo "Starting experiment"

RESULTS_FILENAME=$TYPE_DIR-$APP_NAME-"$(date +%s)"-$REP.csv

echo "Number of executions [$REP]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,ExecID,ReqID,Value" > $RESULTS_FILENAME

for i in $(seq "$REP")
do
	echo "Rep $i..."
	if [ "$TYPE_DIR" == "server-http-handler" ];
	then
		scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME localhost:9000 / $REP $i $JAR_PATH >> $RESULTS_FILENAME
	elif [ "$TYPE_DIR" == "std-server-handler" ]
	then
		scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $REP $JAR_PATH $i >> $RESULTS_FILENAME
	else 
		echo "Could not identify the experiment type [$TYPE_DIR]"
	fi
done
