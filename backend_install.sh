#!/bin/bash
#
#

#Variables
declare -a judgeVMIP
vagrantDispatcherInitPath=dispatcher/vagrant_dispatcher_init.sh
vagrantJudgeInitPath=judge/vagrant_judge_init.sh
dispatcherDirPath=~/
judgeDirPath=/var/nthuoj
machineStatusDir=machineStatus/
machineConfigPath=machine.config
logFilePath=log/dispatcher.log
dataPathGuest=/var/nthuoj/data
numberOfJudgeVM=3

#install start
##############
echo -e "MYSQL user name"
read -p ">" mysqlUsername
echo -e "MYSQL password"
read -p ">" mysqlPassword
echo -e "Database IP"
read -p ">" databaseIP
echo -e "Dispatcher folder path in VM"
read -p ">" dispatcherDirPath
echo -e "Judge folder path in VM"
read -p ">" judgeDirPath
echo -e "Data folder path in Host machine"
read -p ">" dataPathHost
echo -e "Data folder path in dispatcher and judge VMs"
read -p ">" dataPathGuest
echo -e "Dispatcher IP"
read -p ">" dispatcherIP
echo -e "Number of judge VM"
read -p ">" numberOfJudgeVM
for i in $(seq 0 $((${numberOfJudgeVM}-1)))
do
	echo -e "judge VM ${i} IP"
	read -p ">" judgeVMIP[${i}]
done

[ "${dataPathHost:$((${#dataPathHost}-1))}" == "/" ] && dataPathHost=${dataPathHost::-1}
[ "${dataPathGuest:$((${#dataPathGuest}-1))}" == "/" ] && dataPathGuest=${dataPathGuest::-1}
[ "${dispatcherDirPath:$((${#dispatcherDirPath}-1))}" == "/" ] && dispatcherDirPath=${dispatcherDirPath::-1}
[ "${judgeDirPath:$((${#judgeDirPath}-1))}" == "/" ] && judgeDirPath=${judgeDirPath::-1}

mkdir dispatcher
########
#Create Vagrant file for dispatcher
########
content=""
content=${content}"# -*- mode: ruby -*-\n"
content=${content}"# vi: set ft=ruby :\n"
content=${content}"\n"
content=${content}"Vagrant.configure(2) do |config|\n"
content=${content}"\n"
content=${content}"  config.vm.define :dispatcher do |dispatcher|\n"
content=${content}"    dispatcher.vm.box = \"ubuntu/trusty64\"\n"
content=${content}"    dispatcher.vm.network \"private_network\", ip: \"${dispatcherIP}\"\n"
content=${content}"    dispatcher.vm.synced_folder \"${dataPathHost}\", \"${dataPathGuest}\"\n"
#content=${content}"    dispatcher.vm.provision \"shell\", path: \"vagrant_dispatcher_init.sh\"\n"
content=${content}"  end\n"
content=${content}"\n"
content=${content}"end\n"
echo -e "${content}" | tee dispatcher/Vagrantfile
########
#Create provision script for dispatcher
########
content=""
content=${content}"#!bin/bash\n"
content=${content}"dispatcherDirPath=${dispatcherDirPath}\n"
content=${content}"dataPathGuest=${dataPathGuest}\n"
content=${content}"mysqlUsername=${mysqlUsername}\n"
content=${content}"mysqlPassword=${mysqlPassword}\n"
content=${content}"databaseIP=${databaseIP}\n"
content=${content}"\n"
content=${content}"\n"
content=${content}"sudo apt-get update\n"
content=${content}"sudo apt-get install -y git openssh-server php5 apache2 php5-mysql php5-curl mysql-server\n"
content=${content}"sudo service apache2 start\n"
content=${content}"sudo mkdir \${dispatcherDirPath}\n"
content=${content}"cd \${dispatcherDirPath}\n"
content=${content}"sudo git clone https://github.com/nthuoj/NTHUOJ_backend.git\n"
content=${content}"sudo mv NTHUOJ_backend/dispatcher/ ./dispatcher/\n"
content=${content}"sudo rm -r NTHUOJ_backend\n"
content=${content}"cd dispatcher/\n"
content=${content}"sudo mkdir log\n"
content=${content}"sudo touch log/dispatcher.log\n"
content=${content}"sudo mkdir machineStatus\n"
content=${content}"sudo ln -s \${dispatcherDirPath}\"/resultUpdater.php\" /var/www/html/\n"
echo -e "${content}" | tee ${vagrantDispatcherInitPath}
	#generate nthuoj.ini
echo "content=\"\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"[database]\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\";Default MYSQL user name\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"username = \${mysqlUsername}\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\";Default MYSQL password\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"password = \${mysqlPassword}\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\";Database IP\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"ip = \${databaseIP}\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\";Data folder\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"data = \${dataPathGuest}\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\";Dispatcher path\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "content=\${content}\"dispatcher = \${dispatcherDirPath}/dispatcher/dispatcher.php\n\"" | tee -a ${vagrantDispatcherInitPath}
echo "echo -e \"\${content}\" | sudo tee nthuoj.ini" | tee -a ${vagrantDispatcherInitPath}
	#generate machine.config
content="content=\"\""
echo "${content}" | tee -a ${vagrantDispatcherInitPath}
for i in $(seq 0 $((${numberOfJudgeVM}-1)))
do
	content=""
	content=${content}"content=\${content}\"judge${i} ${judgeVMIP[${i}]}\n\""
	echo "${content}" | tee -a ${vagrantDispatcherInitPath}
done
echo "echo -e \"\${content}\" | sudo tee machine.config" | tee -a ${vagrantDispatcherInitPath}

content=""
content=${content}"cd ..\n"
content=${content}"sudo chown -R vagrant:vagrant dispatcher\n"
echo -e "${content}" | tee -a ${vagrantDispatcherInitPath}

mkdir judge
########
#Create Vagrant file for judge
########
content=""
content=${content}"# -*- mode: ruby -*-\n"
content=${content}"# vi: set ft=ruby :\n"
content=${content}"\n"
content=${content}"Vagrant.configure(2) do |config|\n"
content=${content}"\n"
for i in $(seq 0 $((${numberOfJudgeVM}-1)))
do
	content=${content}"  config.vm.define :judge${i} do |judge${i}|\n"
	content=${content}"    judge${i}.vm.box = \"ubuntu/trusty64\"\n"
	content=${content}"    judge${i}.vm.network \"private_network\", ip: \"${judgeVMIP[${i}]}\"\n"
	content=${content}"    judge${i}.vm.synced_folder \"${dataPathHost}\", \"${dataPathGuest}\"\n"
#	content=${content}"    judge${i}.vm.provision \"shell\", path: \"vagrant_judge_init.sh\"\n"
	content=${content}"  end\n"
done
content=${content}"\n"
content=${content}"end\n"
echo -e "${content}" | tee -a judge/Vagrantfile

########
#Create provision script for judge
########
content=""
content="#!bin/bash\n"
content=${content}"sudo apt-get update\n"
content=${content}"sudo apt-get install -y git apache2 php5 php5-curl timeLimit g++\n"
content=${content}"sudo mkdir ${judgeDirPath}\n"
content=${content}"cd ${judgeDirPath}\n"
content=${content}"sudo git clone https://github.com/bruce3557/NTHUOJ_backend.git\n"
content=${content}"cd NTHUOJ_backend/\n"
content=${content}"sudo git checkout dev\n"
content=${content}"sudo mv ./VM/* ../\n"
content=${content}"cd ..\n"
content=${content}"sudo rm -r NTHUOJ_backend\n"
content=${content}"sudo mkdir judgeFile\n"
content=${content}"sudo mkdir log\n"
content=${content}"cd judgeFile/\n"
content=${content}"sudo mkdir testdata\n"
content=${content}"cd ../log/\n"
content=${content}"sudo mkdir errs\n"
content=${content}"sudo touch interface.log\n"
content=${content}"sudo touch nthuoj.log\n"
content=${content}"cd ..\n"
content=${content}"sudo chown -R www-data:www-data judgeFile\n"
content=${content}"sudo chown -R www-data:www-data log\n"
content=${content}"sudo chmod +x judge/*.sh\n"
content=${content}"sudo chmod +x interface/*.php\n"
content=${content}"sudo ln -s nthuoj.config /etc/nthuoj/\n"
content=${content}"sudo ln -s ${judgeDirPath}/interface/*.php /var/www/html/\n"
content=${content}"sudo mkdir /etc/nthuoj\n"
echo -e "${content}" | tee ${vagrantJudgeInitPath}
	#generate nthuoj.config
echo "content=\"\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"for interface only\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tdispatcherIP = ${dispatcherIP}\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\treturnPage = resultUpdater.php\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tsourceDir = ${dataPathGuest}"/code/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tspeJudgeDir = ${dataPathGuest}"/specialJudge/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tparJudgeDir = ${dataPathGuest}"/partialJudge/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\ttestdataDir = ${dataPathGuest}"/testdata/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\terrMsgDir = ${judgeDirPath}"/log/errs/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tjudge = ${judgeDirPath}"/judge/judge.sh"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tinterface.log = ${judgeDirPath}"/log/interface.log"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tdebug mode = 0\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"for both\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tjudgeFileDir = ${judgeDirPath}"/judgeFile/"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\terrMsg = ${judgeDirPath}"/judgeFile/errMsg"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tresult = ${judgeDirPath}"/judgeFile/result"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tjudge.config = ${judgeDirPath}"/judgeFile/judge.config"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"for judge only\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\truncode = ${judgeDirPath}"/judge/runcode.sh"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tblacklist = ${judgeDirPath}"/judge/blacklist"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tnthuoj.log = ${judgeDirPath}"/log/nthuoj.log"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tc compile arg = -O2 -lm -std=c99\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\tcpp compile arg = -O2 -lm -std=c++11\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\toutputLimit = 32\n\"" | tee -a ${vagrantJudgeInitPath}
echo "content=\${content}\"\n\"" | tee -a ${vagrantJudgeInitPath}
echo "echo -e \"\${content}\" | sudo tee /etc/nthuoj/nthuoj.config" | tee -a ${vagrantJudgeInitPath}

