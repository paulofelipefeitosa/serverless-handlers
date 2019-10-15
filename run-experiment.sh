#!/bin/bash
set -e
TYPE_DIR=$1 # server-http-handler or std-server-handler
RUNTIME=$2 # java, nodejs, python
APP_NAME=$3 # APP DIR NAME
IMAGE_URL=$4 # URL to download image
REP_EXEC=$5 # integer value
REP_REQ=$6 # integer value
HANDLER_TYPE=$7 # criu or no-criu

for i in "$@"
do
	case $i in
		-t=*|--tracer_dir=*) # Tracer directory
		TRACER_DIR="${i#*=}"
		shift # past argument=value
		;;
		-t_eb=*|--tracer_executor_binary=*) # Tracer executor binary path
		TRACER_EB="${i#*=}"
		shift # past argument=value
		;;
		-sfjar=*|--sf_jar_name=*) # Synthetic Function Jar Path
		SF_JAR_PATH="${i#*=}"
		shift # past argument=value
		;;
		-ev=*|--evict=*) # Evict files from filesystem caching
		EVICT="${i#*=}" # PAGES - Evict memory page file, ALL - All criu dump files, any other case - do not evict any file.
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

APP_DIR=$TYPE_DIR/$RUNTIME/$APP_NAME
if [ -n "$SF_JAR_PATH" ];
then
	SF_JAR_NAME=$(basename $SF_JAR_PATH)
fi

if [ -n "$TRACER_EB" ];
then
	BPFTRACE_EXEC="YES"
fi

HTTP_SERVER_ADDRESS=localhost:9000
CRIU_APP_OUTPUT=app.log

clean_env() {
	echo "Killing any conflicting app"
	set +e
	killall -v -w node python3 java
	set -e
}

build_criu_app() {
	if [ $RUNTIME == "java" ];
	then
		criu_builder=$TYPE_DIR/$RUNTIME/java-criu-builder.sh
	elif [ $RUNTIME == "nodejs" ];
	then
		criu_builder=$TYPE_DIR/$RUNTIME/nodejs-criu-builder.sh
	elif [ $RUNTIME == "python" ];
	then
		criu_builder=$TYPE_DIR/$RUNTIME/python-criu-builder.sh
	fi

	clean_env

	echo "Building $APP_DIR App"
	bash $criu_builder "build" $APP_DIR $SF_JAR_PATH

	echo "Running $APP_DIR App"
	bash $criu_builder "dump" $APP_DIR $HTTP_SERVER_ADDRESS $CRIU_APP_OUTPUT -scale=0.1 -image_path=$IMAGE_PATH -sfjar=$SF_JAR_PATH -warm=$WARM_REQ

	cd $APP_DIR
	if [ $EVICT == "ALL" ];
	then
		echo "Evicting all criu dump files"
		FILES_LIST=$(ls | grep ".img$")
	elif [ $EVICT == "PAGES" ];
	then
		echo "Evicting the memory pages file"
		FILES_LIST=$(ls | grep "pages.*\.img$")
	else
		FILES_LIST=""
	fi
	
	for file in $FILES_LIST
	do
		dd of="$file" oflag=nocache conv=notrunc,fdatasync count=0
	done
	cd -
}

build_default_app() {
	if [ $RUNTIME == "java" ];
	then
		if [ -z "$SF_JAR_PATH" ];
		then
			cd $APP_DIR
			echo "Building $APP_DIR App to Jar"
			mvn install
			cd -
		fi
	fi
	
	clean_env
}

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
RESULTS_FILENAME=$TYPE_DIR-$RUNTIME-$HANDLER_TYPE-$APP_NAME-$CURRENT_TS-$REP_EXEC-$REP_REQ-$WARM_REQ-$SF_JAR_NAME-$BPFTRACE_EXEC.csv

echo "Number of executions [$REP_EXEC]"
echo "Number of requests [$REP_REQ]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,ExecID,ReqID,KernelTime_NS" > $RESULTS_FILENAME

BPFTRACE_OUT=$(pwd)/$TYPE_DIR-$RUNTIME-$HANDLER_TYPE-$APP_NAME-$CURRENT_TS-$REP_EXEC-$REP_REQ-$WARM_REQ-$SF_JAR_NAME-BPFTRACE.out
run_bpftrace() {
	if [ -n "$BPFTRACE_EXEC" ];
	then 
		killall -v -w bpftrace
		>&2 echo "Running bpftrace probes"

		bpftrace -B 'line' $TRACER_DIR/execve-clone-probes.bt ${EXP_APP_NAME:0:15} $TRACER_EB > $BPFTRACE_OUT &
		BPFTRACER_PID=$!
		>&2 echo "BPFTracer PID=$BPFTRACER_PID"

		while [ $(wc -c "$BPFTRACE_OUT" | awk '{print $1}') -eq 0 ];
		do
			sleep 1
		done

		echo "$BPFTRACER_PID"
	fi
}

parse_bpftrace() {
	if [ -n "$BPFTRACE_EXEC" ];
	then 
		EXECID=$1
		EXEC_SUCCESS=$2
		BPFTRACER_PID=$3

		PREVIOUS_LOG_SIZE=$(wc -c "$BPFTRACE_OUT" | awk '{print $1}')
		echo "Killing bpftracer with pid=$BPFTRACER_PID"
		kill -SIGINT $BPFTRACER_PID

		if [ $EXEC_SUCCESS -eq 0 ];
		then
			while [ $(wc -c "$BPFTRACE_OUT" | awk '{print $1}') -eq $PREVIOUS_LOG_SIZE ];
			do
				sleep 1
			done
			set +e
			python -u $TRACER_DIR/execve-clone-parser-bpftrace.py $EXECID < $BPFTRACE_OUT >> $RESULTS_FILENAME
			set -e
		fi
	fi
}

parse_criu_logs() {
	EXECID=$1
	EXEC_SUCCESS=$2

	if [ $EXEC_SUCCESS -eq 0 ];
	then
		python -u $TRACER_DIR/criu-restore-parser.py $EXECID < $APP_DIR/restore.log >> $RESULTS_FILENAME
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
				set +e
				build_criu_app
				set -e

				BPFTRACER_PID=$( run_bpftrace )

				echo "Running execute requests script"
				set +e
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $RUNTIME $APP_DIR $HANDLER_TYPE $APP_DIR/$CRIU_APP_OUTPUT >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?
				EXECUTOR_PID=$!

				echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"
				set -e

				parse_bpftrace $i $EXECUTION_SUCCESS $BPFTRACER_PID
				parse_criu_logs $i $EXECUTION_SUCCESS
			else
				echo "HTTP Server Handler"
				build_default_app

				BPFTRACER_PID=$( run_bpftrace )

				echo "Running execute requests script"
				scale=0.1 image_path=$IMAGE_PATH ./$EXP_APP_NAME $HTTP_SERVER_ADDRESS / $REP_REQ $i $RUNTIME $APP_DIR $HANDLER_TYPE $SF_JAR_PATH >> $RESULTS_FILENAME
				EXECUTION_SUCCESS=$?

				echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"

				parse_bpftrace $i $EXECUTION_SUCCESS $BPFTRACER_PID
			fi
		else
			echo "Could not identify the experiment type [$TYPE_DIR]"
			exit -1
		fi
	done
done
