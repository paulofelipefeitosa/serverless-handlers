#!/bin/bash
OUTPUT_FILENAME=$1
if [ -z "$OUTPUT_FILENAME" ]
then
    echo "["$(date +%s%N)"] Run Command" && strace -fff -ttt -e trace=clone,fork,execve LD_LIBRARY_PATH=`pwd` java -agentlib:agent -classpath . Nothing
else
    echo "["$(date +%s%N)"] Run Command" > $OUTPUT_FILENAME && strace -fff -ttt -e trace=clone,fork,execve LD_LIBRARY_PATH=`pwd` java -agentlib:agent="$OUTPUT_FILENAME" -classpath . Nothing
fi
