#!/bin/bash
set -e
TYPE_DIR=$1 # server-http-handler or std-server-handler
APP_NAME=$2 # APP DIR NAME
IMAGE_URL=$3 # URL to download image
REP_EXEC=$4 # integer value
REP_REQ=$5 # integer value
HANDLER_TYPE=$6 # criu or no-criu

for i in "$@"
do
	case $i in
	    -jvm=*|--jvm_path=*) # CRIU: /usr/lib/jvm/java-8-oracle
	    OPT_PATH="${i#*=}"
	    shift # past argument=value
	    ;;
	    -t=*|--tracer_dir=*) # Agent Dir
	    TRACER_DIR="${i#*=}"
	    shift # past argument=value
	    ;;
	    -jar=*|--jar_name=*) # Jar Name to no criu executions
	    JAR_NAME="${i#*=}"
	    shift # past argument=value
	    ;;
	    -gc|--enable_gc) # Enable force GC request
	    GC=YES
	    shift # past argument with no value
	    ;;
	    -sfjar=*|--sf_jar_name=*) # Synthetic Function Jar Path
	    SF_JAR_NAME="${i#*=}"
	    shift # past argument=value
	    ;;
	    -warm|--warm_req) # Enable warm request
	    WARM_REQ=YES
	    shift # past argument with no value
	    ;;
	    *)
	          # unknown option
	    ;;
	esac
done

APP_DIR=$TYPE_DIR/$APP_NAME
JAR_PATH=$APP_DIR/target/$JAR_NAME
SF_JAR_PATH=target/$SF_JAR_NAME

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
	gcc -shared -fpic -I"/usr/lib/jvm/java-6-sun/include" -I"$OPT_PATH/include/" -I"$OPT_PATH/include/linux/" GC.c -o libgc.so

	set +e
	killall -v java
	sleep 1
	set -e

	echo "Running $APP_DIR App"
	echo "" > $CRIU_APP_OUTPUT
	scale=0.1 image_path=$IMAGE_PATH setsid java -Djvmtilib=${PWD}/libgc.so -classpath . App $SF_JAR_PATH  < /dev/null &> $CRIU_APP_OUTPUT &
	sleep 1

	APP_PID=$(pgrep java)
	echo "App PID [$APP_PID]"
	ps aux | grep java

	if [ -n "$WARM_REQ" ];
	then 
		echo "Warming $APP_DIR App"
		while [[ "$(curl --header 'X-Warm-Request: true' -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/ping)" != "200" ]]; 
		    do sleep 1;
		done
	fi

	if [ -n "$GC" ];
	then
		echo "Forcing $APP_DIR GC"
		if [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/gc)" != "200" ]];
		then
			echo "Unable to force GC, please check your application"
			exit 1
		fi
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

CURRENT_TS=$(date +%s)
RESULTS_FILENAME=$TYPE_DIR-$APP_NAME-$CURRENT_TS-$REP_EXEC-$REP_REQ-$GC-$WARM_REQ-$SF_JAR_NAME.csv

echo "Number of executions [$REP_EXEC]"
echo "Number of requests [$REP_REQ]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,ExecID,ReqID,KernelTime_NS" > $RESULTS_FILENAME

BPFTRACE_OUT=$(pwd)/$TYPE_DIR-$APP_NAME-$CURRENT_TS-$REP_EXEC-$REP_REQ-$GC-$WARM_REQ-$SF_JAR_NAME-BPFTRACE.out
run_bpftrace() {
	if [ -n "$TRACER_DIR" ];
	then 
		echo "Running bpftrace probes"

		bpftrace -B 'line' $TRACER_DIR/execve-clone-probes.bt > $BPFTRACE_OUT &

		while [ $(wc -c "$BPFTRACE_OUT" | awk '{print $1}') -eq 0 ];
		do
			sleep 1
		done
	fi
}

parse_bpftrace() {
	if [ -n "$TRACER_DIR" ];
	then 
		EXECID=$1
		PROCESS_COMMAND=$2
		BIN_NAME=$3
		EXEC_SUCCESS=$4

		killall -v bpftrace

		if [ $EXEC_SUCCESS -eq 0 ];
		then
			python -u $TRACER_DIR/execve-clone-parser-bpftrace.py $EXECID $PROCESS_COMMAND $BIN_NAME < $BPFTRACE_OUT >> $RESULTS_FILENAME
		fi
	fi
}

for i in $(seq "$REP_EXEC")
do
	echo "REP_EXEC $i..."
	EXECUTION_SUCCESS=-1
	while [ $EXECUTION_SUCCESS -ne 0 ];
	do
		if [ $TYPE_DIR == "server-http-handler" ];
		then
			if [ $HANDLER_TYPE == "criu" ];
			then
				echo "HTTP Server CRIU Handler"
				dump_criu_app

				run_bpftrace

				echo "Running execute requests script"
				set +e
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $APP_DIR $HANDLER_TYPE $APP_DIR/$CRIU_APP_OUTPUT >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?

				echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"

				echo "Trying to kill HTTP Server Handler process"
				killall -v java
				set -e

				parse_bpftrace $i "execute" "criu" $EXECUTION_SUCCESS

				truncate --size=0 $APP_DIR/$CRIU_APP_OUTPUT
			else
				echo "HTTP Server Handler"

				run_bpftrace

				echo "Running execute requests script"
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $JAR_PATH $HANDLER_TYPE $SF_JAR_PATH >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?

				echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"

				parse_bpftrace $i "execute" "java" $EXECUTION_SUCCESS
			fi
		elif [ $TYPE_DIR == "std-server-handler" ]
		then
			echo "STD Handler of Type [$HANDLER_TYPE]"
			set +e
			
			scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $REP_REQ $JAR_PATH $i $HANDLER_TYPE >> $RESULTS_FILENAME
			EXECUTION_SUCCESS=$?

			echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"

			set -e
		else
			echo "Could not identify the experiment type [$TYPE_DIR]"
			exit -1
		fi
	done
done
