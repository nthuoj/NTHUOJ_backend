<?php
/************************
dispatcherFunction.php
This php provides dispatcher related functions.
Mainly for 'dispatcher.php', 'submit_curl.php' and 'resultUpdater.php'
************************/
require_once(dirname(__FILE__)."/../lib/database_tools.php");

$machineStatusDir="machineStatus/";
$logFilePath="../log/dispatcher.log";

/************************
This function load information from machine.config
*************************/
function getMachine()
{
	//load machine information from machine.config
	$handle = fopen("machine.config", "r");
	if($handle)
	{
		$i=0;
		while ($buffer = fscanf($handle,"%s %s\n"))
		{
			list($machineName[$i], $machineIP[$i]) = $buffer;
			$result[] = array(
                                'machineName' => $machineName[$i],
                                'machineIP' => $machineIP[$i]);
			echo "machinefile:".$i." machineName: ".$machineName[$i]." machineIP: ".$machineIP[$i]."<br>\n";
			$i++;
		}
	}
	fclose($handle);
	return $result;
}

/**********************
This initials files act as the communication between dispatccher and resultUpdater.php.
Each file indicates that whether a machine (judge VM) is available or not.
***********************/
function initMachine($machine)
{
	global $machineStatusDir;
	$cmd = "test -d " . $machineStatusDir . " && rm -r " . $machineStatusDir . "; mkdir " . $machineStatusDir;
	pclose(popen($cmd, "r"));
	foreach($machine as $value)
	{
		$cmd = "echo 0 > ".$machineStatusDir.$value['machineName'].".status";
		pclose(popen($cmd, "r"));
	}
}

/***********************
Given '$machine' with all machines' information, return a machine who is available to judge right now.
************************/
function getIdleMachine($machine)
{
	global $machineStatusDir;
	$destMachine=null;
	foreach($machine as $value)
	{
		$handle = fopen($machineStatusDir.$value['machineName'].".status", "r");
		if($handle)
    	{
			$buffer = fscanf($handle,"%d");
			list($status) = $buffer;
		}
		fclose($handle);
		if($status==0)
		{
			echo "find Idle Machine".$value['machineName']."\n";
			setMachineStatus($value['machineName'], 1);
			//$cmd = "echo 1 > ".$machineStatusDir.$value['machineName'].".status";
			//pclose(popen($cmd, "r"));
			$destMachine['machineName'] = $value['machineName'];
			$destMachine['machineIP'] = $value['machineIP'];
			break;
		}
	}
	return $destMachine;
}

/**************************
Given '$machineName' and '$status', set the '$status' into the specific machine's status file.
**************************/
function setMachineStatus($machineName, $status)
{
	global $machineStatusDir;
	$cmd = "echo ".$status." > ".$machineStatusDir.$machineName.".status";
	//pclose(popen($cmd, "r"));
	shell_exec($cmd);
}

/*******************************
Given '$pid' and '$sid', get the required information to judge a submission: tid, time/memory limit, special judge...
********************************/
function getSubmissionInfo($pid, $sid)
{
	$con = get_database_object();
	$tidQuery = "SELECT * FROM problem_testcase WHERE problem_id = '$pid'";
        $tidRs = mysql_query($tidQuery) or die(mysql_error());
        $j=0;
        while( $tidRow = mysql_fetch_array($tidRs))
        {
			$tid[]=$tidRow['id'];
			$timeLimit[] = $tidRow['time_limit'];
			$memoryLimit[] = $tidRow['memory_limit'];
			echo "tid:".$tid[$j]."\n";
			echo "timeLimit:".$timeLimit[$j]."\n";
			echo "memoryLimit:".$memoryLimit[$j]."\n";
			$j++;
        }

        $pidQuery = "SELECT * FROM problem_problem WHERE id = '$pid'";
        $pidRs = mysql_query($pidQuery) or die(mysql_error());
        $pidRow = mysql_fetch_array($pidRs);
        $judge_type = $pidRow['judge_type'];
        $judge_language = $pidRow['judge_language'];
	echo "judge_type ".$judge_type."\n";
	echo "judge_language ".$judge_language."\n"; 

	$result = array( "tid"=>$tid,
                         "timeLimit"=>$timeLimit, "memoryLimit"=>$memoryLimit,
                         "judge_type"=>$judge_type, "judge_language"=>$judge_language);
	return $result;
}

/************************
This write '$msg' to dispatcher's log file.
************************/
function writeLog($msg)
{
	global $logFilePath;
	$time = "[".date("D M j G:i:s Y")."]  ";
	$cmd = "echo ".$time.$msg." >> ".$logFilePath;
    	//pclose(popen($cmd, "r"));
	shell_exec($cmd);
}
?>
