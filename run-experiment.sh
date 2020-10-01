#!/bin/bash
set -e
TYPE_DIR="functions"
RUNTIME=$1      # java, nodejs, python
APP_NAME=$2     # The name of the APP
REP_EXEC=$3     # Number of executions
HANDLER_TYPE=$4 # criu or no-criu
EXEC_CONFIG=$5  # Filepath to the execution config.

for i in "$@"
do
	case $i in
		-t_eb=*|--executor_process_name=*) # Tracer executor binary path
		TRACER_EB="${i#*=}"
		shift # past argument=value
		;;
		-sfjar=*|--sf_jar_path=*) # Synthetic Function Jar Path
		SF_JAR_PATH="${i#*=}"
		shift # past argument=value
		;;
		-warm|--warm_req) # Enable warm request
		WARM_REQ=YES
		shift # past argument with no value
		;;
		-ios|--iostats) # Enable IO stats tracing
		IO_STATS=YES
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
	bash $criu_builder "dump" $APP_DIR $HTTP_SERVER_ADDRESS $CRIU_APP_OUTPUT -sfjar=$SF_JAR_PATH -warm=$WARM_REQ
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
EXP_APP_NAME="$TYPE_DIR"
source /etc/profile
cd $TYPE_DIR
go build
cd -

echo "Starting experiment"

CURRENT_TS=$(date +%s)
RESULTS_FILENAME=$RUNTIME-$HANDLER_TYPE-$APP_NAME-$CURRENT_TS-$REP_EXEC-$WARM_REQ-$SF_JAR_NAME-$BPFTRACE_EXEC.csv

echo "Number of executions [$REP_EXEC]"
echo "Results filename [$RESULTS_FILENAME]"

echo "Metric,ExecID,ReqID,Value" > $RESULTS_FILENAME

BPFTRACE_OUT=$(pwd)/$RUNTIME-$HANDLER_TYPE-$APP_NAME-$CURRENT_TS-$REP_EXEC-$WARM_REQ-$SF_JAR_NAME-BPFTRACE.out
BCCTRACE_OUT=$(pwd)/$RUNTIME-$HANDLER_TYPE-$APP_NAME-$CURRENT_TS-$REP_EXEC-$WARM_REQ-$SF_JAR_NAME-BCC.out
for i in $(seq "$REP_EXEC")
do
	echo "REP_EXEC $i..."
	EXECUTION_SUCCESS=-1
	while [ $EXECUTION_SUCCESS -ne 0 ];
	do
    if [ $HANDLER_TYPE == "criu" ];
    then
      echo "HTTP Server CRIU Handler"
      set +e
      build_criu_app
      set -e

      BPFTRACER_PID=$(EXEC=$BPFTRACE_EXEC bash clone-exec-bpftrace.sh run $BPFTRACE_OUT $EXP_APP_NAME $TRACER_EB)
      BCCTRACER_PID=$(EXEC=$IO_STATS bash iostats-tracer.sh run $BCCTRACE_OUT)

      echo "Running execute requests script"
      set +e
      ./$TYPE_DIR/$EXP_APP_NAME $HTTP_SERVER_ADDRESS $i $RUNTIME $APP_DIR $HANDLER_TYPE $EXEC_CONFIG $APP_DIR/$CRIU_APP_OUTPUT >> $RESULTS_FILENAME
      EXECUTION_SUCCESS=$?
      EXECUTOR_PID=$!

      echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"
      set -e

      EXEC=$BPFTRACE_EXEC bash clone-exec-bpftrace.sh parse $BPFTRACE_OUT $i $EXECUTION_SUCCESS $BPFTRACER_PID $RESULTS_FILENAME
      EXEC=$IO_STATS bash iostats-tracer.sh parse $BCCTRACE_OUT $EXECUTION_SUCCESS $BCCTRACER_PID
      bash criu-logs-tracer.sh parse $i $EXECUTION_SUCCESS $APP_DIR $RESULTS_FILENAME
    else
      echo "HTTP Server Handler"
      build_default_app

      BPFTRACER_PID=$(EXEC=$BPFTRACE_EXEC bash clone-exec-bpftrace.sh run $BPFTRACE_OUT $EXP_APP_NAME $TRACER_EB)
      BCCTRACER_PID=$(EXEC=$IO_STATS bash iostats-tracer.sh run $BCCTRACE_OUT)

      echo "Running execute requests script"
      ./$TYPE_DIR/$EXP_APP_NAME $HTTP_SERVER_ADDRESS $i $RUNTIME $APP_DIR $HANDLER_TYPE $EXEC_CONFIG $SF_JAR_PATH >> $RESULTS_FILENAME
      EXECUTION_SUCCESS=$?

      echo "$EXP_APP_NAME exit code [$EXECUTION_SUCCESS]"

      EXEC=$BPFTRACE_EXEC bash clone-exec-bpftrace.sh parse $BPFTRACE_OUT $i $EXECUTION_SUCCESS $BPFTRACER_PID $RESULTS_FILENAME
      EXEC=$IO_STATS bash iostats-tracer.sh parse $BCCTRACE_OUT $EXECUTION_SUCCESS $BCCTRACER_PID
    fi
	done
done
