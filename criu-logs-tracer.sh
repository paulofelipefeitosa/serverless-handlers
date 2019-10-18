TYPE=$1

if [ $TYPE == "parse" ];
then
	EXECID=$2
	EXEC_SUCCESS=$3
	APP_DIR=$4
	RESULTS_FILENAME=$5

	if [ $EXEC_SUCCESS -eq 0 ];
	then
		python -u probes-specs/criu-restore-parser.py $EXECID < $APP_DIR/restore.log >> $RESULTS_FILENAME
	fi
else
	echo "Cannot identify tracer behavior type [$TYPE]"
	exit 1
fi