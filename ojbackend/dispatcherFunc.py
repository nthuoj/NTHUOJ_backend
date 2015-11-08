"""
	dispatcherFunc.py
	This file provides related functions for dispatcher.php.	
"""
from bash import bash
import MySQLdb


def getMachine():
    #load judge information from judge.config
    #the information include judge name, ip address
    machineInfo = {}
    with open("machineInfo.config",'r') as f:
        try:        
            for line in f: 
                (machine, ip) = line.split()
                machineInfo[machine] = ip
            return machineInfo
        except:
            print "encounter troubles when opening machineInfo.config"
            return None


def initMachine(machineInfo):
    #create a dir and a file for machineStatus
    #0 means availabe, 1 means occupied
    try:
        bash('test -d machineStatusDir  && rm -r machineStatusDir')
        bash('mkdir machineStatusDir')
        with open("machineStatusDir/machineStatus.config",'w') as f:
            for machineName in machineInfo.keys():
                f.write(machineName + " 0\n")
    except:
        print "encounter troubles when rm machineStatusDir or mkdir machineStatusDir"
        return None


def getIdleMachine():
    #to get the machine which is available for judging
    machinePosition = 0
    IdleMachine = ''
    try:
        with open("machineStatusDir/machineStatus.config",'r+') as f:
            for line in f:
                if(line.split()[1] == '0'):
                    machineName = line.split()[0]
                    f.seek(machinePosition + len(machineName) + 1, 0)
                    f.write('1')
                    IdleMachine = machineName
                    return IdleMachine
                    break
                machinePosition = machinePosition + len(line)
            return None
    except:
        return None


def getdbInfo():
    with open("ojdatabase.config",'r') as f:
        try:
            for line in f:
                if(line.split()[0] == "host"):
                    dbIP = line.split()[2]
                elif(line.split()[0] == "user"):
                    dbUser = line.split()[2]
                elif(line.split()[0] == "passwd"):
                    dbPasswd = line.split()[2]
                elif(line.split()[0] == "db"):
                    dbName = line.split()[2]
        except:
            print "Log dbInfo Error\nPlease check ojdatabase.config"
            return None, None, None, None
    return dbIP, dbUser, dbPasswd, dbName


def connectDB(dbIP, dbUser, dbPasswd, dbName):
    try:
        DB = MySQLdb.connect(host = dbIP, user = dbUser, passwd = dbPasswd, db = dbName)
        print "connect db success\n"
        return DB
    except:
        print "connect DB error\n"
        return None
