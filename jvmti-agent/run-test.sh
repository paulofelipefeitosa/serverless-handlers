#!/bin/bash
OUTPUT_FILENAME=$1
ABS_PATH=`pwd`
#echo "strace -fff -ttt -T -e trace=fork,clone,execve,mmap,openat"
if [ -z "$OUTPUT_FILENAME" ]
then
    #bpftrace -c "java -agentpath:${ABS_PATH}/libagent.so -classpath . Nothing" read.bt
    java -agentpath:${ABS_PATH}/libagent.so -classpath . Nothing
else
    truncate --size=0 $OUTPUT_FILENAME
    #bpftrace -c "java -agentpath:${ABS_PATH}/libagent.so=${OUTPUT_FILENAME} -classpath . Nothing" read.bt
    java -agentpath:${ABS_PATH}/libagent.so=${OUTPUT_FILENAME} -classpath . Nothing >> $OUTPUT_FILENAME
fi
