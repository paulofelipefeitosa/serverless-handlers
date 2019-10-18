TYPE=$1
BPFTRACE_OUT=$2

if [ $TYPE == "run" ];
then
	EXP_APP_NAME=$3 #
	TRACER_EB=$4 # Executor Binary

	killall -v -w bpftrace
	>&2 echo "Running clone and exec bpftrace probes"

	bpftrace -B 'line' probes-specs/execve-clone-probes.bt ${EXP_APP_NAME:0:15} $TRACER_EB > $BPFTRACE_OUT &
	BPFTRACER_PID=$!
	>&2 echo "BPFTracer PID=$BPFTRACER_PID"

	while [ $(wc -c "$BPFTRACE_OUT" | awk '{print $1}') -eq 0 ];
	do
		sleep 1
	done

	echo "$BPFTRACER_PID"
elif [ $TYPE == "parse" ];
then
	EXECID=$3
	EXEC_SUCCESS=$4
	BPFTRACER_PID=$5
	RESULTS_FILENAME=$6

	echo "Killing bpftracer with pid=$BPFTRACER_PID"
	kill -SIGINT $BPFTRACER_PID

	if [ $EXEC_SUCCESS -eq 0 ];
	then
		sync
		set +e
		python -u probes-specs/execve-clone-parser-bpftrace.py $EXECID < $BPFTRACE_OUT >> $RESULTS_FILENAME
		set -e
	fi
else
	echo "Cannot identify tracer behavior type [$TYPE]"
	exit 1
fi