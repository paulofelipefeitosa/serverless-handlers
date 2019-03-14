#!/bin/bash
set -e
TYPE_DIR=$1 # server-http-handler or std-server-handler
APP_NAME=$2 # APP DIR NAME
JAR_NAME=$3 # JAR NAME
IMAGE_URL=$4 # URL to download image
REP_EXEC=$5 # integer value
REP_REQ=$6 # integer value
HANDLER_TYPE=$7 # criu or no-criu
PATH2JVM_INCLUDES=$8 # /usr/lib/jvm/java-8-oracle

APP_DIR=$TYPE_DIR/$APP_NAME
JAR_PATH=$APP_DIR/target/$JAR_NAME

HTTP_SERVER_ADDRESS=localhost:9000
CRIU_APP_OUTPUT=app.log

dump_criu_app() {
	cd $APP_DIR

	echo "Remove any previous dump files"
	set +e
	rm *.img
	set -e

	echo "Building $APP_DIR App Classes"
	javac *.java
	gcc -shared -fpic -I"/usr/lib/jvm/java-6-sun/include" -I"$PATH2JVM_INCLUDES/include/" -I"$PATH2JVM_INCLUDES/include/linux/" GC.c -o libgc.so

	set +e
	killall -v java
	sleep 1
	set -e

	echo "Running $APP_DIR App"
	echo "" > $CRIU_APP_OUTPUT
	scale=0.1 image_path=$IMAGE_PATH setsid java -Djvmtilib=${PWD}/libgc.so -classpath . App  < /dev/null &> $CRIU_APP_OUTPUT &
	sleep 1

	APP_PID=$(pgrep java)
	echo "App PID [$APP_PID]"
	ps aux | grep java

	echo "Warming $APP_DIR App"
	while [[ "$(curl --header 'X-Warm-Request: true' -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/ping)" != "200" ]]; 
	    do sleep 1;
	done
	curl http://$HTTP_SERVER_ADDRESS/gc

	lsof -p $APP_PID

	echo "Dumping $APP_DIR App"
	criu dump -t $APP_PID -vvv -o dump.log
	DUMP_EXIT_STATUS=$?
	if [ $DUMP_EXIT_STATUS -ne 0 ];
	then
		echo "Dump App $APP_DIR failed"
		exit 1
	fi

	cd -
}

if [ "$HANDLER_TYPE" != "criu" ];
then
	cd $APP_DIR

	echo "Building $APP_DIR App to Jar [$JAR_PATH]"
	mvn install

	cd -
fi


echo "Building experiment"
EXP_APP_NAME="execute-requests"
source /etc/profile
go build $TYPE_DIR/"$EXP_APP_NAME".go

echo "Downloading image from [$IMAGE_URL]"
cd $APP_DIR
IMAGE_NAME=$(basename $IMAGE_URL)
wget -O $IMAGE_NAME $IMAGE_URL
IMAGE_PATH=$(pwd)/$IMAGE_NAME
cd -

echo "Starting experiment"

RESULTS_FILENAME=$TYPE_DIR-$APP_NAME-"$(date +%s)"-$REP_EXEC-$REP_REQ.csv

echo "Number of executions [$REP_EXEC]"
echo "Number of requests [$REP_REQ]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,ExecID,ReqID,Value" > $RESULTS_FILENAME

for i in $(seq "$REP_EXEC")
do
	echo "REP_EXEC $i..."
	EXECUTION_SUCCESS=-1
	while [ $EXECUTION_SUCCESS -ne 0 ];
	do
		if [ "$TYPE_DIR" == "server-http-handler" ];
		then
			if [ "$HANDLER_TYPE" == "criu" ];
			then
				echo "HTTP Server CRIU Handler"
				dump_criu_app

				set +e
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $APP_DIR $HANDLER_TYPE $APP_DIR/$CRIU_APP_OUTPUT >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?

				echo "Try to kill HTTP Server Handler process"
				pgrep java
				killall -v java
				set -e

				truncate --size=0 $APP_DIR/$CRIU_APP_OUTPUT
			else
				echo "HTTP Server Handler"

				set +e
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $JAR_PATH $HANDLER_TYPE "no-path" >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?
				set -e
			fi
		elif [ "$TYPE_DIR" == "std-server-handler" ]
		then
			echo "STD Handler of Type [$HANDLER_TYPE]"
			set +e
			scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $REP_REQ $JAR_PATH $i $HANDLER_TYPE >> $RESULTS_FILENAME
			EXECUTION_SUCCESS=$?
			set -e
		else
			echo "Could not identify the experiment type [$TYPE_DIR]"
			exit -1
		fi
	done
done
