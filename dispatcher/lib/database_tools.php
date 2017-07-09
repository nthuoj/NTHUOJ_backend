<?php
/*****************
 * database_tools.php$DB_DATA = $arr['data'];
 * This sets the basic information of database connection.
 * **************/
global $arr;
$arr = parse_ini_file(dirname(__FILE__)."/../nthuoj.ini");
 
$DB_LOCATE = $arr['ip']; // set the DB IP
$DB_USER = $arr['username']; // set the DB user
$DB_PASSWD = $arr['password']; // set the DB password
$DB_DATA = $arr['data'];
/*****************
 * This builds a DB connection, and return the db connection instance.
 * **************/

function get_database_object($db_name='newoj') //  default db name could be reset.
{
    global $DB_LOCATE;
    global $DB_USER;
    global $DB_PASSWD;

    $con = mysql_connect($DB_LOCATE, $DB_USER, $DB_PASSWD, true);
    if(!$con)   die("Could not connect: ". mysql_error());
    mysql_select_db($db_name, $con);
    return $con;
}

?>
