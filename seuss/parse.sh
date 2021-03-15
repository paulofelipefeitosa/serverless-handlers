#!/bin/bash

LOG_FILE=$1
RESULTS_FILE=$2

records=$(awk '/Scheduling activation/{getline; print}' "$LOG_FILE")

echo "req_id, duration, start_ts, end_ts, status, wait_time, init_time, run_time, resp" > "$RESULTS_FILE"

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
  echo "${AR_FIRST[index]}, ${AR_WAIT[index]}, ${AR_INIT[index]}, ${AR_RUN[index]}, \"{${AR_RESP[index]}" >> "$RESULTS_FILE"
done