#!/bin/bash

TYPE=$1
APP_DIR=$2

if [ $TYPE == "build" ];
then
	echo "Build Java App"
	cd $APP_DIR

	echo "Remove any previous dump files or java app"
	set +e
	rm *.img
	killall -v java
	set -e

	javac *.java
	gcc -shared -fpic -I"/usr/lib/jvm/java-6-sun/include" -I"$OPT_PATH/include/" -I"$OPT_PATH/include/linux/" GC.c -o libgc.so

	cd -
elif [ $TYPE == "dump" ];
	echo "Dump Java App"
	cd $APP_DIR

	HTTP_SERVER_ADDRESS=$3
	CRIU_APP_OUTPUT=$4
	for i in "$@"
	do
		case $i in
		    -sfjar=*|--sf_jar_name=*) # Synthetic Function Jar Path
		    SF_JAR_PATH="${i#*=}"
		    shift # past argument=value
		    ;;
		    -warm=*|--warm_req=*) # Enable warm request
		    WARM_REQ="${i#*=}"
		    shift # past argument=value
		    ;;
		    -scale=*|--scale=*) # Synthetic Function Jar Path
		    SCALE="${i#*=}"
		    shift # past argument=value
		    ;;
		    -image_path=*|--image_path=*) # Enable warm request
		    IMAGE_PATH="${i#*=}"
		    shift # past argument=value
		    ;;
		    *)
		          # unknown option
		    ;;
		esac
	done
	truncate --size=0 $CRIU_APP_OUTPUT
	scale=$SCALE image_path=$IMAGE_PATH setsid java -Djvmtilib=${PWD}/libgc.so -classpath . App $SF_JAR_PATH  < /dev/null &> $CRIU_APP_OUTPUT &

	APP_PID=$(pgrep java)
	echo "Java App PID [$APP_PID]"
	ps aux | grep java

	if [ -n "$WARM_REQ" ];
	then 
		echo "Warming $APP_DIR App"
		while [[ "$(curl --header 'X-Warm-Request: true' -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/ping)" != "200" ]]; 
		    do sleep 1;
		done
	fi

	echo "Dumping $APP_DIR App"
	criu dump -t $APP_PID -vvv -o dump.log
	DUMP_EXIT_STATUS=$?
	if [ $DUMP_EXIT_STATUS -ne 0 ];
	then
		echo "Dump App $APP_DIR failed"
		exit 1
	fi

	cd -
else
	echo "Cannot identify builder behavior type [$TYPE]"
	exit 1
fi