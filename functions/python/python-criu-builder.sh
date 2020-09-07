#!/bin/bash

TYPE=$1
APP_DIR=$2

if [ $TYPE == "build" ];
then
	echo "Build Python App"
	cd $APP_DIR

	echo "Remove any previous dump files"
	set +e
	rm *.img

	cd -
elif [ $TYPE == "dump" ];
then
	echo "Dump Python App"
	cd $APP_DIR

	HTTP_SERVER_ADDRESS=$3
	CRIU_APP_OUTPUT=$4
	for i in "$@"
	do
		case $i in
		    -warm=*|--warm_req=*) # Enable warm request
		    WARM_REQ="${i#*=}"
		    shift # past argument with no value
		    ;;
		    *)
		          # unknown option
		    ;;
		esac
	done
	truncate --size=0 $CRIU_APP_OUTPUT
	truncate --size=0 app.err
	setsid python3 -u app.py < /dev/null > $CRIU_APP_OUTPUT 2> app.err &

	APP_PID=$(pgrep python3)
	echo "Python App PID [$APP_PID]"
	ps aux | grep python3

	if [ -n "$WARM_REQ" ];
	then 
		echo "Warming $APP_DIR App"
		while [[ "$(curl --header 'X-Warm-Request: true' -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/)" != "200" ]]; 
		    do sleep 1;
		done
	else
		echo "Waiting until $APP_DIR App is ready without Warmup"
		while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://$HTTP_SERVER_ADDRESS/ping)" != "200" ]]; 
		    do sleep 1;
		done
	fi

	echo "Dumping $APP_DIR App"
	criu dump -t $APP_PID -vvv -o dump.log
	DUMP_EXIT_STATUS=$?
	if [ $DUMP_EXIT_STATUS -ne 0 ];
	then
		echo "Dump App $APP_DIR failed"
		return 18
	fi

	cd -
else
	echo "Cannot identify builder behavior type [$TYPE]"
	return 1
fi