#!/bin/bash
OUTPUT_FILENAME=$1
ABS_PATH=`pwd`
if [ -z "$OUTPUT_FILENAME" ]
then
    java -agentpath:${ABS_PATH}/libagent.so -classpath . Nothing
else
    java -agentpath:${ABS_PATH}/libagent.so=${OUTPUT_FILENAME} -classpath . Nothing >> $OUTPUT_FILENAME
fi
