#!/bin/bash

EXP_ID=$1
LOG_FILEPATH=$2
RESULTS_FILEPATH=$3

echo "Parsing SEUSS log to generate results csv"

records=$(awk '/Scheduling activation/{getline; print}' "$LOG_FILEPATH")

first_part=$(echo "$records" | awk '{split($0,l,",\""); print l[1]}')
sec_part=$(echo "$records" | awk '{split($0,l,",\""); print l[2]}')

wait_time=$(echo "$sec_part" | awk -F '{key:waitTime,value:' '{print $2}' | awk '{split($0,l,"\\},\\{"); print l[1]}')
init_time=$(echo "$sec_part" | awk -F '{key:initTime,value:' '{print $2}' | awk '{split($0,l,"\\}\\{"); print l[1]}')
run_time=$(echo "$sec_part" | awk -F '{key:runTime,value:' '{print $2}' | awk '{split($0,l,"\\}\\{"); print l[1]}')
resp=$(echo "$sec_part" | awk -F '{key:runTime,value:' '{print $2}' | awk '{split($0,l,"\\}\\{"); print l[2]}')

IFS='
'

AR_WAIT=($wait_time)
AR_INIT=($init_time)
AR_RUN=($run_time)
AR_RESP=($resp)
AR_FIRST=($first_part)

for index in "${!AR_WAIT[@]}";
do
  echo "$EXP_ID, ${AR_FIRST[index]}, ${AR_WAIT[index]}, ${AR_INIT[index]}, ${AR_RUN[index]}, \"{${AR_RESP[index]}" >> "$RESULTS_FILEPATH"
done

echo "End of parsing procedure"