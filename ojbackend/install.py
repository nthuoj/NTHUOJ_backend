"""
	install.py
	This file let users to set up machineInfo.config and ojdatabase.config file
"""

from bash import bash
def set_MachineInfo():
    
    bash('test -d machineInfo.config  && rm -r machineInfo.config')    
    num = raw_input("Please input the total number of the judges:\n")
    if num > 0:
        try:
            with open("machineInfo.config",'w') as f:
                for i in range(0,int(num)):
                    judgeName = raw_input("Please input the judge's name:\n")
                    judgeIP = raw_input("Please input the judge's ip:\n")
                    f.write(judgeName + " " + judgeIP + "\n")
        except:
            print "Error occurs when setting machineInfo.config\n"
            exit(0)

def set_OjDatabase():
    bash('test -d ojdatabase.config  && rm -r ojdatabase.config')
    try:
        with open("ojdatabase.config",'w') as f:
            host = raw_input("Please input the ip of the database:\n")
            user = raw_input("Please input the username:\n")
            passwd = raw_input("Please input the password:\n")
            db = raw_input("Please input the name of the database:\n")
            f.write("host = " + host + "\n")
            f.write("user = " + user + "\n")
            f.write("passwd = " + passwd + "\n")
            f.write("db = " + db + "\n")
    except:
        print "Error occurs when setting ojdatabase.config\n"
        exit(0)

set_OjDatabase() 
set_MachineInfo()
       
