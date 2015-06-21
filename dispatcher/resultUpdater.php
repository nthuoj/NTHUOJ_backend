<?php
	
//	require_once("lib/database_tools.php");
	require_once("where U put dispatcherFunction.php");
	$con = get_database_object();
	
	writeLog("updater start");
	$sid = $_POST['sid'];
	$pid = $_POST['pid'];
	$tid = $_POST['tid'];
	$verdict = $_POST['verdict'];
	$runTime = $_POST['runTime'];
	$memoryAmt = $_POST['memoryAmt'];
	$errMsg = $_POST['errMsg'];
	$machineName = $_POST['machineName'];
	$tidNum = count($tid);
	$verdictNum = count($verdict);
	$i=0;
	$ac=0;
	foreach ($verdict as $value)
	{
		echo "verdict ".$i.":".$value."\n";
		if(!strcmp($value,"AC"))
			$ac++;
        $i++;
	}
	$i=0;
	foreach ($runTime as $value)
	{
		echo "runtime ".$i.":".$value."\n";
	    $i++;
	}
	$i=0;
	foreach ($memoryAmt as $value)
	{
		echo "memoryAmt ".$i.":".$value."\n";
	    $i++;
	}
	/*$i=0;
	foreach ($errMsg as $value)
	{
		echo "errMsg ".$i.":".$value."<br>";
	    $i++;
	}*/
	echo $machineName."\n";
	setMachineStatus($machineName, 0);
	writeLog("sid = ".$sid."insert submission detail table tidNum = ".$tidNum);
	$i=0;
	$err = str_replace('\\', '\\\\', $errMsg);
	$err = str_replace('\'', '\\\'', $err);
	switch ($verdict[0]){
		case "CE":
			$status = "CE";
			break;
		case "JE":
			$status = "JE";
			break;
		case "RF":
			$status = "RF";
			break;
		default:
			if ($ac == $tidNum)
				$status = "AC";
			else
				$status = "NA";
			break;
	}
	if((!strcmp($status, "AC"))||(!strcmp($status, "NA"))){
		while($i < $verdictNum){
			$sql = "insert into problem_submissiondetail (verdict, cpu, memory, sid_id, tid_id) value('".$verdict[$i]."',".$runTime[$i].",".$memoryAmt[$i].",".$sid.",".$tid[$i].")";
			writeLog($sql);
			echo $sql."\n";
			mysql_query($sql) or die(mysql_error());
			$i++;
		}
	}
	writeLog("update submission table");

	$sql = "UPDATE problem_submission SET status = '".$status."', error_msg = '".$err[0]."'  WHERE id = ".$sid;
	echo "sql = ".$sql."\n";
    mysql_query($sql) or die(mysql_error());
?>
