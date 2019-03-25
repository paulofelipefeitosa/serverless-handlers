#!/bin/bash
OUTPUT_FILENAME=$1
echo "["$(date +%s%N)"] Run Command" > $OUTPUT_FILENAME && LD_LIBRARY_PATH=`pwd` java -agentlib:agent="$OUTPUT_FILENAME" Nothing
