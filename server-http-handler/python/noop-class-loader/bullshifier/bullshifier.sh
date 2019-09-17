#!/bin/bash

for i in "$@"
do
	case $i in
		-bcp=*|--base_code=*) # Path to the base code that will be copied
		BASE_CODE_PATH="${i#*=}"
		shift 
		;;
		-cps=*|--copies=*) # Number of base code copies 
		COPIES="${i#*=}"
		shift
		;;
		-pre=*|--preffix=*) # String preffix that will be added before the pattern replacement
		PREFFIX="${i#*=}"
		shift
		;;
		-suf=*|--suffix=*) # String suffix that will be added after the pattern replacement
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
	new_filename=$PATTERN$i.$FILE_EXTENSION
	cp $BASE_CODE_PATH $new_filename
	sed -i "s/$PREFFIX$PATTERN$SUFFIX/$PREFFIX$PATTERN$i$SUFFIX/" $new_filename
done