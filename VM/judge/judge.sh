#!/bin/bash

# Arguments:
#	code file absolute path
#	code langauge type (c/cpp)
#	testcase number
#	input folder absolute path
#	output folder absolute path
#	judge type (0:normal judge, 1:special judge, 2:partial judge)
#	special judge / partial judge code absolute path
#	special judge code language type (c/cpp)
#
#
# 1. check input/output data exist
#
# 2. compile submit code and special judge / partial judge code
#	distinguish c/c++ source file
#	determine if Compile Error
#	determine if Restricted Function
#
# 3. run
#	check Runtime Error
#	check TLE
#	not check MLE / OLE yet
#
# 4. compare
#	special judge
#	hard compare
#	determine if Accepted
#	soft compare
#	determine Wrong Answer or Presentation Error



# Arguments
CODE_PATH=$1
CODE_LAN_TYPE=$2
CASE_NUMBER=$3
INPUT_DIR=$4
OUTPUT_DIR=$5
JUDGE_TYPE=$6

# Const variable
EXE_FILE="exeFile"											# execute file name
JUDGE_EXE="judgeExe"										# special judge execute file name
USR_OUT="usrOut"											# user output file name
JUDGE_OUT="judgeOut"										# special judge output file name
PAR_JUDGE_O_FILE="partialJudge.o"							# partial judge object file name
EXE_O_FILE="exeFile.o"										# user execute object file name  
UNDEF_FUNC_FILE="undef.ls"									# a file with all user undefinded function name
JUDGE_LOG="judgeLog"
LOCAL_LOG="localLog"
JUDGE_START_TIME=`date`
OUTPUT_LIMIT="64000"
CONFIG_FILE="/etc/nthuoj/nthuoj.config"





#------------------ functions ---------------------

function writeSystemLog(){
	echo $@ >> $SYSTEM_LOG
	# $@ will get all arguments
}
function writeLocalLog(){
	echo $@ >> $LOCAL_LOG
	# $@ will get all arguments
}
function getConfig(){
	returnValue=$1
	shift
	str=$@
	path=`grep -w "$str =" $CONFIG_FILE | tr -d '\r'`
	path=${path#*= }
	eval "$returnValue='$path'"
}
function setConstVariable(){
	getConfig TESTCASE_CONFIG_FILE 'judge.config'
	getConfig SYSTEM_LOG 'nthuoj.log' 
	getConfig ERR_MSG 'errMsg'
	getConfig RESULT_FILE 'result'
	getConfig C_COMPILE_ARG 'c compile arg'
	getConfig CPP_COMPILE_ARG 'cpp compile arg'
	getConfig RUNCODE_PATH 'runcode'
	getConfig BLACKLIST_FILE 'blacklist'
	getConfig JUDGE_FILE_DIR 'judgeFileDir'
}

function cleanTmpFile(){
	# Remove generated files
	cd ..
#	rm -r $OUTPUT_TMP_DIR
}

function getResult(){

	# check and remove result file
	if [ -f $RESULT_FILE ]; then
		rm $RESULT_FILE
	fi
	
	# get the lastest judge log in str
	str=`cat $LOCAL_LOG`
	
	for (( i=1; i<=$CASE_NUMBER; i++ )) do
		
		# get one case result 
		str=${str#*Testing case $i}
		
		if [ i != $CASE_NUMBER ]; then
			caseResult=${str%Testing case $(($i+1))*}
		else
			caseResult=$str
		fi
		
		echo $caseResult > $JUDGE_LOG
		
		# get execution time in caseResult
		caseResult=${caseResult#*Time:} #abandon the characters before 'Time:' including 'Time:'
		caseResult=${caseResult%%ms*} #abandon the characters after 'ms' including 'ms'
			
		if grep -q -w "COMPILE_ERROR" $JUDGE_LOG ; then
			echo -n "COMPILE_ERROR" >> $RESULT_FILE
			echo -n " 0" >> $RESULT_FILE
			break;
		elif grep -q -w "RESTRICTED_FUNCTION" $JUDGE_LOG; then
			echo -n "RESTRICTED_FUNCTION" >> $RESULT_FILE
			echo -n " 0" >> $RESULT_FILE 
			break;
		elif grep -q -w "RUNTIME_ERROR" $JUDGE_LOG; then
			echo -n "RUNTIME_ERROR" >> $RESULT_FILE
			echo -n " 0" >> $RESULT_FILE
		elif grep -q -w "TIME_LIMIT_EXCEED" $JUDGE_LOG; then
			echo -n "TIME_LIMIT_EXCEED" >> $RESULT_FILE
			echo -n ""$caseResult >> $RESULT_FILE
		elif grep -q -w "ACCEPTED" $JUDGE_LOG; then
			echo -n "ACCEPTED" >> $RESULT_FILE
			echo -n ""$caseResult >> $RESULT_FILE
		elif grep -q -w "PRESENTATION_ERROR" $JUDGE_LOG; then
			echo -n "PRESENTATION_ERROR" >> $RESULT_FILE
			echo -n ""$caseResult >> $RESULT_FILE
		elif grep -q -w "WRONG_ANSWER" $JUDGE_LOG; then
			echo -n "WRONG_ANSWER" >> $RESULT_FILE
			echo -n ""$caseResult >> $RESULT_FILE
		elif grep -q -w "OUTPUT_LIMIT_EXCEEDED" $JUDGE_LOG; then
			echo -n "OUTPUT_LIMIT_EXCEEDED" >> $RESULT_FILE
			echo -n ""$caseResult >> $RESULT_FILE
		else
			echo -n "JUDGE_ERROR" >> $RESULT_FILE
			echo -n " 0" >> $RESULT_FILE
			echo " -1" >> $RESULT_FILE
			break
		fi
		
		echo " -1" >> $RESULT_FILE
		
	done
	sed -i 's/\/var\/nthuoj\/judgeFile\//\ /g' $ERR_MSG
	writeSystemLog "judge end : "`date`
	
}

#------------------------------------------------------

setConstVariable



# judge start
writeSystemLog ""
writeSystemLog $JUDGE_START_TIME
writeSystemLog "JUDGE_START"

if [ $# -lt 6 ]; then
	echo "usage: ./judge code_path code_lan test_number in_path out_path judge_type [judge_code_path] [judge_lan]"
	writeSystemLog "ARGUMENT_ERROR"
	getResult
	exit 1
fi


# Check special judge code / partial judge code exist
if [ "$JUDGE_TYPE" != "NORMAL" ]; then
	if [ $# -ne 8 ]; then
		echo "usage: ./judge code_path code_lan test_number in_path out_path judge_type [judge_code_path] [judge_lan]"
		writeSystemLog "ARGUMENT_ERROR"
		getResult
		exit 1
	else
		if [ "$JUDGE_TYPE" == "SPECIAL" ]; then
			SPE_JUDGE_PATH=$8
			SPE_JUDGE_LAN_TYPE=$7
		elif [ "$JUDGE_TYPE" == "PARTIAL" ]; then
			PAR_JUDGE_PATH=$8
			PAR_JUDGE_LAN_TYPE=$7
		fi
	fi
fi


# Check code exist
if [ ! -f $CODE_PATH ]; then
	writeSystemLog "CODE_NOT_EXIST"
	getResult
	exit 2
else
	writeSystemLog "CODE_EXIST"
fi

# Check input data exist
if [ ! -d $INPUT_DIR ]; then
	writeSystemLog "INPUT_DIR_NOT_EXIST"
	getResult
	exit 2
else
	writeSystemLog "INPUT_DIR_EXIST"
	for (( i=1; i<=$CASE_NUMBER; i++ )) do
		if [ ! -f $INPUT_DIR/in$i ]; then
			writeSystemLog "IN"$i"_NOT_EXIST"
			getResult
			exit 2
		else
			writeSystemLog "IN"$i"_EXIST"
		fi
	done
fi

# Check output data exist
if [ ! -d $OUTPUT_DIR ]; then
	writeSystemLog "OUTPUT_DIR_NOT_EXIST"
	getResult
	exit 2
else
	writeSystemLog "OUTPUT_DIR_EXIST"
	for (( i=1; i<=$CASE_NUMBER; i++ )) do
		if [ ! -f $OUTPUT_DIR/out$i ]; then
			writeSystemLog "OUT"$i"_NOT_EXIST"
			getResult
			exit 2
		else
			writeSystemLog "OUT"$i"_EXIST"
		fi
	done
fi

OUTPUT_TMP_DIR=${JUDGE_FILE_DIR}"outTmpDir"
# clean last judge buffer
if [ -d $OUTPUT_TMP_DIR ]; then
	rm -r $OUTPUT_TMP_DIR
fi

if [ -f $ERR_MSG ]; then
	rm $ERR_MSG
fi

# Create temp direction
mkdir $OUTPUT_TMP_DIR
cd $OUTPUT_TMP_DIR


# compile submit code to object file
writeSystemLog "Compile submit code to object file"
if [ $CODE_LAN_TYPE = "c" ]; then
	writeSystemLog "Compile as c"
	gcc -c $CODE_PATH $C_COMPILE_ARG -o $EXE_O_FILE 2> $ERR_MSG

elif [ $CODE_LAN_TYPE = "cpp" ]; then
	writeSystemLog "Compile as cpp"
	g++ -c $CODE_PATH $CPP_COMPILE_ARG -o $EXE_O_FILE 2> $ERR_MSG

else
	writeSystemLog "UNSUPPORTED LANGUAGE TYPE" $CODE_LAN_TYPE
	getResult
	cleanTmpFile
	exit 1
fi
# Check whether complie success
if [ ! -f $EXE_O_FILE ]; then
	writeLocalLog "COMPILE_ERROR"
	writeSystemLog "COMPILE_ERROR"
	getResult
	cleanTmpFile
	exit 3
else
	writeSystemLog "OBJECT_COMPILE_SUCCESS"
fi

OBJECT_FILES=${EXE_O_FILE}
# Compile partial judge code to object file and combine to object_files 
if [ "$JUDGE_TYPE" == "PARTIAL" ]; then
	writeSystemLog "Compile partial judge code"
	if [ $CODE_LAN_TYPE = "c" ]; then
		writeSystemLog "Compile as c"
		if [ ! -f $PAR_JUDGE_PATH ]; then
			writeLocalLog "COMPILE_ERROR"
			writeSystemLog "COMPILE_ERROR"
			getResult
			cleanTmpFile
			exit 3
		fi
		gcc -c $PAR_JUDGE_PATH $C_COMPILE_ARG -o $PAR_JUDGE_O_FILE 2> $ERR_MSG
	elif [ $CODE_LAN_TYPE = "cpp" ]; then
		writeSystemLog "Compile as cpp"
		if [ ! -f $PAR_JUDGE_PATH ]; then
			writeLocalLog "COMPILE_ERROR"
			writeSystemLog "COMPILE_ERROR"
			getResult
			cleanTmpFile
			exit 3
		fi
		g++ -c $PAR_JUDGE_PATH $CPP_COMPILE_ARG -o $PAR_JUDGE_O_FILE 2> $ERR_MSG
	else
		writeSystemLog "UNSUPPORTED LANGUAGE TYPE" $CODE_LAN_TYPE
		getResult
		cleanTmpFile
		exit 1
	fi
	OBJECT_FILES=${EXE_O_FILE}" "${PAR_JUDGE_O_FILE}
	# Check whether complie success
	if [ ! -f $PAR_JUDGE_O_FILE ]; then
		writeLocalLog "JUDGE_ERROR"
		writeSystemLog "JUDGE_ERROR"
		getResult
		cleanTmpFile
		exit 3
	else
		writeSystemLog "PARTIAL_OBJECT_COMPILE_SUCCESS"
	fi
fi


# Compile object files
if [ $CODE_LAN_TYPE = "c" ]; then
	writeSystemLog "Compile as c"
	gcc $OBJECT_FILES $C_COMPILE_ARG -o $EXE_FILE 2> $ERR_MSG

elif [ $CODE_LAN_TYPE = "cpp" ]; then
	writeSystemLog "Compile as cpp"
	g++ $OBJECT_FILES $CPP_COMPILE_ARG -o $EXE_FILE 2> $ERR_MSG

else
	writeSystemLog "UNSUPPORTED LANGUAGE TYPE" $CODE_LAN_TYPE
	getResult
	cleanTmpFile
	exit 1
fi

# Check whether complie success
if [ ! -f $EXE_FILE ]; then
	writeLocalLog "COMPILE_ERROR"
	writeSystemLog "COMPILE_ERROR"
	getResult
	cleanTmpFile
	exit 3
else
	writeSystemLog "COMPILE_SUCCESS"
fi

# Restricted function
if [ $CODE_LAN_TYPE = "c" ]; then
	gcc -ansi -c $CODE_PATH -o $EXE_O_FILE

elif [ $CODE_LAN_TYPE = "cpp" ]; then
	g++ -c $CODE_PATH -o $EXE_O_FILE

else
	writeSystemLog "UNSUPPORTED LANGUAGE TYPE" $CODE_LAN_TYPE
	getResult
	cleanTmpFile
	exit 1
fi

# create user undefined function list
nm -u -fp $EXE_O_FILE > $UNDEF_FUNC_FILE

haveRestrictedFunction=0
# read function names in blacklist one by one
writeSystemLog `cat $UNDEF_FUNC_FILE` 
while read LINE
do
	if tr -d '\t\n\r\f'  < $UNDEF_FUNC_FILE | grep -q -w $LINE; then
		haveRestrictedFunction=1
		echo $LINE >> $ERR_MSG 
	fi
	
done < $BLACKLIST_FILE

if [ $haveRestrictedFunction -eq 1 ]; then
	writeLocalLog "RESTRICTED_FUNCTION"
	writeSystemLog "RESTRICTED_FUNCTION"
	getResult
	cleanTmpFile
	exit 4
fi

# Compile special judge code
if [ "$JUDGE_TYPE" == "SPECIAL" ]; then
	if [ $SPE_JUDGE_LAN_TYPE = "C" ]; then
		writeSystemLog "Compile special code as c"
		gcc $SPE_JUDGE_PATH $C_COMPILE_ARG -o $JUDGE_EXE 2> $ERR_MSG

	elif [ $SPE_JUDGE_LAN_TYPE = "CPP" ]; then
		writeSystemLog "Compile special code as cpp"
		g++ $SPE_JUDGE_PATH $CPP_COMPILE_ARG -o $JUDGE_EXE 2> $ERR_MSG

	else
		writeSystemLog "UNSUPPORTED LANGUAGE TYPE" $SPE_JUDGE_LAN_TYPE
		getResult
		cleanTmpFile
		exit 1
	fi
	
	# Check whether compile success
	if [ ! -f $JUDGE_EXE ]; then
		writeSystemLog "SPECIAL_JUDGE_COMPILE_ERROR"
		cat $ERR_MSG
		getResult
		cleanTmpFile
		exit 3
	else
		writeSystemLog "SPECIAL_JUDGE_COMPILE_SUCCESS"
	fi
	
fi


# Run and compare
for (( i=1; i<=$CASE_NUMBER; i++ )) do
	
	read TIME_LIMIT
	read MEMORY_LIMIT
	
	writeLocalLog "Testing case" $i
	writeSystemLog "Testing case" $i
	writeSystemLog "Time limit:" $TIME_LIMIT
	writeSystemLog "Memory limit" $MEMORY_LIMIT

	writeSystemLog "start runcode"`date`
	# Run
	$RUNCODE_PATH $PWD/$EXE_FILE $INPUT_DIR/in$i $USR_OUT $TIME_LIMIT $MEMORY_LIMIT $OUTPUT_LIMIT $SYSTEM_LOG $LOCAL_LOG
	result=$?	
	writeSystemLog "finish runcode"`date`
	if [ $result -ne 0 ]; then
		if [ $result -eq 1 ]; then
			writeLocalLog "RUNTIME_ERROR"
			writeSystemLog "RUNTIME_ERROR"
		elif [ $result -eq 2 ]; then
			writeLocalLog "TIME_LIMIT_EXCEED"
			writeSystemLog "TIME_LIMIT_EXCEED"
		elif [ $result -eq 5 ]; then
			writeLocalLog "runcode error"
			writeSystemLog "runcode error"
		else
			writeLocalLog "RUNTIME_ERROR"
			writeSystemLog "RUNTIME_ERROR"
		fi
		# TODO: MLE / OLE
		
	else
#		if [ ! -f $USR_OUT ]; then
#			writeSystemLog "RUNTIME_ERROR"
#			continue
#		else
#			writeSystemLog "have usr_our"
#		fi
#		str=`ls -l | grep $USR_OUT`
#
#		for word in $str;do
#      			if [ $word -gt 32768000 ];then
#				writeLocalLog "OUTPUT_LIMIT_EXCEEDED"
#				writeSystemLog "OUTPUT_LIMIT_EXCEEDED"
#				break
#			fi
#		done
#		if [ $word -gt 32768000 ];then
#			continue;
#		fi
		# Compare
		if [ "$JUDGE_TYPE" == "SPECIAL" ]; then
			# Special judge
			writeSystemLog "Start special judge.."
			ulimit -t $(( $TIME_LIMIT+1 ))
			./$JUDGE_EXE $INPUT_DIR/in$i $USR_OUT > $JUDGE_OUT
			SPE_JUDGE_EXIT_CODE=$?
			if [ $SPE_JUDGE_EXIT_CODE -ne 0 ]; then
				writeSystemLog "SPECIAL_JUDGE_RUN_ERROR"
				continue
			fi
			mv $JUDGE_OUT $USR_OUT
		fi
			
		# hard compare
		diff $USR_OUT $OUTPUT_DIR/out$i > /dev/null
		if [ $? -eq 0 ]; then
			writeLocalLog "ACCEPTED"
			writeSystemLog "ACCEPTED"
		else
			# soft compare
			# replace all '\n' with ' ' in user_out and answer_out 
#			str=$(cat $USR_OUT)
#			str=${str/"\n"/ }
#			echo $str > $USR_OUT
#			str=$(cat $OUTPUT_DIR/out$i)
#			str=${str/"\n"/ }
#			echo $str > $OUTPUT_DIR/softOut$i
			diff -b -B $USR_OUT $OUTPUT_DIR/out$i > /dev/null
			if [ $? -eq 0 ]; then
				writeLocalLog "PRESENTATION_ERROR"
				writeSystemLog "PRESENTATION_ERROR"
			else
				writeLocalLog "WRONG_ANSWER" 
				writeSystemLog "WRONG_ANSWER" 
			fi
		fi
	fi
	
	writeSystemLog "testing case finish"
done < $TESTCASE_CONFIG_FILE

getResult
cleanTmpFile
