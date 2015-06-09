<?php
/************************
dispatcher.php
This process continuously checks whether there exist unjudged submissions.
If there's unjudged submissions, start 'submit_curl.php' process to send it to a available judge VM.
**************************/


require_once("dispatcherFunction.php");


writeLog("================================");
writeLog("================================");

$machine = getMachine();
if($machine!=null)
	initMachine($machine);
else
	writeLog("get machine file error");
print_r($machine);

$i=0;
echo "submit_test start<br>";
writeLog("dispatcher start");
while(1)
{
	/*sleep(10);*/
	$con = get_database_object();
    $sidQuery = "SELECT * FROM problem_submission WHERE status = 'WAIT' ORDER BY id ASC LIMIT 100";
    $sidRs = mysql_query($sidQuery) or die(mysql_error());
	
	echo "sidRsNum".mysql_num_rows($sidRs)."\n";
	while( $sidRow = mysql_fetch_array($sidRs) ) {
		$sid = $sidRow['id'];	
		$pid = $sidRow['problem_id'];
		$problemQuery = "SELECT * FROM problem_problem where id = '$pid'";
		$problemRs = mysql_query($problemQuery);
		$problemRow = mysql_fetch_array($problemRs);
		$judge_source = $problemRow['judge_source'];
		$outside_web = $problemRow['judge_type']; 
		$codeLanType = $sidRow['language'];
		
		if($judge_source == "LOCAL")
		{	
			$findMachine = 0;
			echo "before findmachine\n";
			writeLog("before find machine");
			$destMachine = null;
			while($destMachine==null)
			{
				$destMachine = getIdleMachine($machine);
				sleep(1);
			}

			if($destMachine != null)
			{
				echo "destMachineName=".$destMachine['machineName']."   destMachineIP=".$destMachine['machineIP']."\n";
				writeLog("submission ".$sid." use ".$destMachine['machineName'].":".$destMachine['machineIP']."to judge");
			}
			else
			{
				echo "destMachine=null!!\n";
				writeLog("find machine error");
			}
		
			$con = get_database_object();
			$updQuery = "UPDATE problem_submission SET status = 'JUDGING' WHERE id = ".$sid;
			echo $updQuery."   ".$sid."\n";
			mysql_query($updQuery) or die(mysql_error());
			$judgeIP = $destMachine['machineIP'];
			$judgePage = "interface.php";
			$judgeURL = $judgeIP."/".$judgePage;
			echo "judgeURL=".$judgeURL."\n";	
		
			echo "send!\n";

			writeLog("send info to judge ".$destMachine['machineName'].":".$destMachine['machineIP']);
			$arg = $sid." ".$pid." ".$codeLanType." ".$destMachine['machineName']." ".$judgeURL;
			$handle = popen("/usr/bin/php submit_curl.php ".$arg." & >> output.html", "w");
			pclose($handle);
			echo "after popen\n";
		}
		else
		{
			$con = get_database_object();
            $updQuery = "UPDATE problem_submission SET status = 'JUDGING' WHERE id = ".$sid;
            echo $updQuery."   ".$sid."\n";
            mysql_query($updQuery) or die(mysql_error());
			
			writeLog("send info to other judge");
			$arg = $codeLanType." ".$pid." ".$outside_web." ".$sid;
			if(file_exists("/var/nthuoj/outsideConnection/sendToOtherJudge.sh"))
			{
				$handle = popen("/var/nthuoj/outsideConnection/sendToOtherJudge.sh ".$arg." & >> output.html", "w");
				pclose($handle);
			}
			else
				writeLog("send info to other judge error(no judge)");

		}
	}

	sleep(10);
	$i++;
}
echo "submit_test finished\n";
writeLog("dispatcher finished");
?>
