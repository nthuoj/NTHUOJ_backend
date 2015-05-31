<?php

/***********************************************************************/
/* Parameters
/* 	key: php post key
/*	&val: 
/*
/* Return value
/*	0 if get key successful
/*	1 if key doesn't exist
/*
/* Description
/*	Give a php post key, receive its value and store it into &val.
/*
/***********************************************************************/
function recvInfo($key, &$val){
	global $_POST;
	if(array_key_exists($key, $_POST)){
		$val = $_POST[$key];
		writeLog($key." = ".$val);
		return 0; // success
	}
	else{
		writeLog("No ".$key);
		return 1; // key doesn't exist
	}
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*	0 if copy file successful
/*	1 if copy file fail
/*
/* Description
/*
/***********************************************************************/
function moveFile($srcFile, $tarFile){
	global $DEBUG_MODE;

	writeLog("Coping ".$srcFile." to ".$tarFile);

	// Copy file
	$cmd = "cp ".$srcFile." ".$tarFile;
	if($DEBUG_MODE) echo "$cmd<br>";
	shell_exec($cmd);

	if(!file_exists($srcFile)){
		writeLog("File ".$srcFile." does not exist.");
		return 1; // failure
	}

	if(!file_exists($tarFile)){
		writeLog("Copy ".$tarFile." failed.");
		return 1; // failure
	}

	writeLog("Copy success");

	return 0; // success
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*	0 if parse verdict correctly
/*	1 otherwise
/*
/* Description
/*
/***********************************************************************/
function getVerdict($v, &$verdict, &$errMsg){
	global $JUDGE_FILE_DIR, $ERR_MSG_DIR;
	global $SID;
	global $DEBUG_MODE;

	$errMsg = "null";

	if(strcmp($v, "COMPILE_ERROR") == 0){
		$verdict = "CE";
		$errMsg = shell_exec("cat ".$JUDGE_FILE_DIR."errMsg");
	}
	else if(strcmp($v, "RESTRICTED_FUNCTION") == 0){
		$verdict = "RF";
		$errMsg = shell_exec("cat ".$JUDGE_FILE_DIR."errMsg");
	}
	else if(strcmp($v, "RUNTIME_ERROR") == 0)
		$verdict = "RE";

	else if(strcmp($v, "TIME_LIMIT_EXCEED") == 0)
		$verdict = "TLE";

	else if(strcmp($v, "ACCEPTED") == 0)
		$verdict = "AC";

	else if(strcmp($v, "PRESENTATION_ERROR") == 0)
		$verdict = "PE";

	else if(strcmp($v, "WRONG_ANSWER") == 0)
		$verdict = "WA";

	else if(strcmp($v, "JUDGE_ERROR") == 0)
		$verdict = "JE";

	else if(strcmp($v, "OUTPUT_LIMIT_EXCEEDED") == 0)
		$verdict = "OLE";

	else{ // error, invalid verdict
		writeLog("Invalid verdict");
		return 1; // error, invalid verdict
	}

	writeLog("verdict: ".$verdict);
	shell_exec("cp ".$JUDGE_FILE_DIR."errMsg ".$ERR_MSG_DIR."$SID".".err");

	return 0; // success
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*	None.
/*
/* Description
/*
/***********************************************************************/
function removeFile($path){
	global $DEBUG_MODE;
	
	if(!is_file($path)){
		writeLog("$path is not file");
		return;
	}

	if($DEBUG_MODE) echo "unlink($path)<br>";
	writeLog("Remove ".$path);
	unlink($path);
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*
/* Description
/*
/***********************************************************************/
function clearDirectory($path){
	global $DEBUG_MODE, $JUDGE_DEBUG_MODE;
	global $JUDGE_FILE_DIR;

	if(!is_dir($path)){
		writeLog($path." is not dir");
		return;
	}

	if(strcmp($path, $JUDGE_FILE_DIR."outTmpDir/") == 0){
		writeLog("Do not clear outTmpDir");
		return;
	}

	writeLog("clear ".$path);
	if($DEBUG_MODE) echo "clear($path)<br>";

	// Get all file list
	$files = glob($path."*");
	if($DEBUG_MODE){ print_r($files); echo "<br>"; }

	foreach ($files as $filename){
		if(is_file($filename)) removeFile($filename);
		else if(is_dir($filename)) clearDirectory($filename."/");
		else writeLog("$filename is not file or directory");
	}
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*
/* Description
/*
/***********************************************************************/
function returnResult($verdict, $runTime, $memoryAmt, $errMsg){
	global $DEBUG_MODE;
	global $IP_ADDR, $RETURN_PAGE, $SID, $PID, $TID, $MACHINE_NAME;

	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, "http://$IP_ADDR/$RETURN_PAGE");
	curl_setopt($ch, CURLOPT_POST, true); // start POST 
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query( array(
								"sid"=>$SID, "pid"=>$PID, "tid"=>$TID,
								"machineName"=>$MACHINE_NAME,
								"verdict"=>$verdict,
								"runTime"=>$runTime, 
								"memoryAmt"=>$memoryAmt,
								"errMsg"=>$errMsg) ));
	$exeResult = curl_exec($ch);
	curl_close($ch);

	if($DEBUG_MODE){
		echo "---------updater-----------<br>";
		echo $exeResult;
		echo "---------updater end-----------<br>";
	}
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*
/* Description
/*
/***********************************************************************/
function writeLog($str){
	global $LOG_FILE;
	global $DEBUG_MODE;
	if($DEBUG_MODE){
		echo $str."<br>";
	}
	shell_exec("echo [".date("D M j G:i:s Y")."] ".$str." >> ".$LOG_FILE);
}

/***********************************************************************/
/* Parameters
/*
/* Return value
/*
/* Description
/*
/***********************************************************************/
function judgeError(){
	global $DEBUG_MODE;
	global $JUDGE_FILE_DIR;
	if($DEBUG_MODE) echo "some error occured.<br>";
	$verdict[] = "JE";
	$runTime[] = 0;
	$memoryAmt[] = -1;
	$errMsg[] = "null";
	returnResult($verdict, $runTime, $memoryAmt, $errMsg);
	writeLog("Cleaning judgeFile folder...");
	clearDirectory($JUDGE_FILE_DIR);
	writeLog("Clean judgeFile folder end");
}

?>
