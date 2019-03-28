#!/bin/bash
OUTPUT_FILENAME=$1
ABS_PATH=`pwd`
echo "strace -fff -ttt -T -e trace=fork,clone,execve,mmap,openat"
if [ -z "$OUTPUT_FILENAME" ]
then
    echo "["$(date +%s%N)"] Run Command" && java -agentpath:$ABS_PATH/libagent.so -classpath . Nothing
else
    echo "["$(date +%s%N)"] Run Command" > $OUTPUT_FILENAME && java -agentpath:$ABS_PATH/libagent.so="$OUTPUT_FILENAME" -classpath . Nothing
fi
