#!/bin/bash

# Arguments:
#	execute file absolute path
# 	input file absolute path
#	output file absolute path
#	time limit
#	memory limit
#	output limit
#	log file absolute path


if [ $# -lt 8 ]; then
	echo "usage: ./runcode exe_path in_path out_path t_limit mem_limit out_limit system_log_path local_log_path"
	exit 1
fi

# Parsing Arguments
EXE_FILE=$1
IN_FILE=$2
OUT_FILE=$3
TIME_LIMIT=$4
MEMORY_LIMIT=$5
OUTPUT_LIMIT=$6
SYSTEM_LOG=$7
LOCAL_LOG=$8


TIME_LOG="timeLog"
ERRMSG="runcodeErrmsg"

ulimit -H -t $(( $4+1 ))
ulimit -H -f 32010

# Catch run time
time(timelimit -t$(( $4+1 )) -T$(( $4+1 )) $EXE_FILE < $IN_FILE > $OUT_FILE 2> $ERRMSG) 2> $TIME_LOG
EXIT_CODE=$?
str=$(cat $TIME_LOG)
str=${str#*real} #abandon the characters before 'real' including 'real'
str=${str%user*} #abandon the characters after 'user' including 'user'

minute=${str%m*}
ms=${str#*m}
ms=${ms%\s*}
ms=${ms/./}
for (( i=0 ; i<3 ; i++ )) do
	if [ ${ms:0:1} = "0" ]; then
		ms=${ms:1:4}
	fi
done

totalTime=$(( minute*60000 + ms ))

if [ $EXIT_CODE -ne 0 ]; then
	if [ $totalTime -lt $(($TIME_LIMIT*1000)) ]; then
		# Runtime Error
		echo "Execute Time: 0 ms" >> $LOCAL_LOG
		echo "Execute Time: 0 ms" >> $SYSTEM_LOG
		exit 1
	else
		# Time Limit Exceed
		echo "Execute Time:" $(($TIME_LIMIT*1000)) "ms">> $LOCAL_LOG
		echo "Execute Time:" $(($TIME_LIMIT*1000)) "ms">> $SYSTEM_LOG
		exit 2
	fi
	# TODO: MLE / OLE

else
	if [ $totalTime -lt $(($TIME_LIMIT*1000)) ]; then
		echo "Execute Time:" $totalTime "ms" >> $LOCAL_LOG
		echo "Execute Time:" $totalTime "ms" >> $SYSTEM_LOG
		exit 0
	else
		echo "Execute Time:" $(($TIME_LIMIT*1000)) "ms">> $LOCAL_LOG
		echo "Execute Time:" $(($TIME_LIMIT*1000)) "ms">> $SYSTEM_LOG
                exit 2
        fi

fi


