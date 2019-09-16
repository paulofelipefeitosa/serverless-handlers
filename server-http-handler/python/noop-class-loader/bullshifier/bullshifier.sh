#!/bin/bash

for i in "$@"
do
	case $i in
		-bcp=*|--base_code=*) # Path to the base code that will be copied
		BASE_CODE_PATH="${i#*=}"
		shift 
		;;
		-c=*|--copies=*) # Number of base code copies 
		COPIES="${i#*=}"
		shift
		;;
		-p=*|--preffix=*) # String preffix that will be added before the pattern replacement
		PREFFIX="${i#*=}"
		shift
		;;
		-s=*|--suffix=*) # String suffix that will be added after the pattern replacement
		SUFFIX="${i#*=}"
		shift
		;;
		-ptt=*|--pattern=*) # String Pattern that will be replaced by [Pattern(concat)CopyNumber]
		PATTERN="${i#*=}"
		shift
		;;
		*)
		;;
	esac
done

FILE_EXTENSION=$(echo $BASE_CODE_PATH | awk -F "." '{print $2}')

for i in $(seq "$COPIES")
do
	cp $BASE_CODE_PATH $PATTERN$i$FILE_EXTENSION
done