<?php
/*********************
submit_curl.php
Description: This php send a http POST about submission information to judge VM in order to start judging a submission.
Input Argument: sid(submission ID), pid(problem ID), code language type(C, C++), machine name, judge url
***********************/
require_once("dispatcherFunction.php");

$sid = $_SERVER["argv"][1];
$pid = $_SERVER["argv"][2];
$codeLanType = $_SERVER["argv"][3];
$machineName = $_SERVER["argv"][4];
$judgeURL = $_SERVER["argv"][5];

echo $judgeURL.$sid.$pid.$codeLanType.$machineName."\n\n\n\n\n";

$data = getSubmissionInfo($pid, $sid);
$tid = $data['tid'];
$timeLimit = $data['timeLimit'];
$memoryLimit = $data['memoryLimit'];
$judgeType = $data['judge_type'];
$judgeLanType = $data['judge_language'];
echo $judgeType."\n";
echo $judgeLanType."\n";
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $judgeURL);
curl_setopt($ch, CURLOPT_POST, true); // start POST
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
//curl_setopt($ch, CURLOPT_TIMEOUT, 1);
//curl_setopt($ch, CURLOPT_NOBODY, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query( array( 
	"sid"=>$sid, "tid"=>$tid, 
	"pid"=>$pid,"timeLimit"=>$timeLimit, 
	"memoryLimit"=>$memoryLimit,"codeLanType"=>$codeLanType, 
	"judgeType"=>$judgeType,"judgeLanType"=>$judgeLanType, 
	"machineName"=>$machineName) ));

$result = curl_exec($ch);
echo "===========================\n";
echo "vm interface start\n";
echo $result."\n";
echo "vm interface finished\n";
curl_close($ch);


setMachineStatus($machineName,0);

?>

