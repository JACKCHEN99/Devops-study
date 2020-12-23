#! /bin/bash
# If not specify, default meaning of return value:
# 0: Success
# 1: System error
# 2: Application error
# 3: Network error

CURRENT_SPACE=`pwd`
INSTALL_SPACE="/tmp/private_cloud_install"
UPDATE_SPACE=${CURRENT_SPACE}
BASE_URL="https://callback.ihr360.com/download/private_cloud_stable"

PUBLISH_SCRIPTS="publish.tar.gz"
UPDATE_LISTS="private_update.list"
MAIN_DATABASES="only_for_private_cloud_main_database.tar"
OTHER_DATABASES="only_for_private_cloud_other_database.tar"
DATABASES_SCRIPTS="create_database_and_import_database.sh"

#######color code########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

function downloadFile(){
	DOWNLOADFILENAME=$1
	ADAPTIVEPARS=$2
	if [[ ${ADAPTIVEPARS} == 'updateENV' ]];then 
		DOWNLOADPATH=${UPDATE_SPACE}
	else
		DOWNLOADPATH=${INSTALL_SPACE}/${ADAPTIVEPARS}
	fi

	rm ${DOWNLOADPATH}/${DOWNLOADFILENAME} -rf
	wget -P ${DOWNLOADPATH} ${BASE_URL}/${DOWNLOADFILENAME}
	if [[ $? -ne 0 ]]; then
                colorEcho ${RED} "Faild to download ${DOWNLOADFILE}.Please download it manually from callback.ihr360.com"
                return 3
        fi	
	return 0
}

function serverInit(){
	colorEcho ${BLUE} "installing base services..."
	installSoftware wget || return $?
	colorEcho ${BLUE} "Starting to Initialize environment..."
	downloadFile template-init-config.tar.gz base-config
	mv /etc/apt/sources.list /etc/apt/sources.list.bak
	tar -xvf ${INSTALL_SPACE}/base-config/template-init-config.tar.gz -C /
	sysctl -p && apt update
	grep "docker.ihr360.com" /etc/hosts > /dev/null 2>&1 || echo "112.64.175.162  docker.ihr360.com" >> /etc/hosts
	return 0
}

function check(){
	colorEcho ${BLUE} "Checking to server environmet, please wait a moment..."
	ServerVersion=`awk -F "=" '{if($1=="PRETTY_NAME") print $2}' /etc/os-release`
	colorEcho ${BLUE} 'Server version:' ${ServerVersion}
	return 0
}

function installSoftware(){
	COMPONENT=$1
	if [[ -n `command -v $COMPONENT` ]]; then
		return 0
	fi
	
	colorEcho ${BLUE} "installing ${COMPONENT}"
	apt install -y ${COMPONENT}

	if [[ $? -ne 0 ]]; then
		colorEcho ${RED} "Faild to install ${COMPONENT}.Please install it manually"
		return 1
	fi
	return 0
}

function installNginx(){
	colorEcho ${BLUE} "Installing Nginx..."
	installSoftware nginx || return $?
	colorEcho ${YELLOW} "backup nginx default config:/etc/nginx -> /etc/nginx.bak"
	mv /etc/nginx /etc/nginx.bak
	colorEcho ${BLUE} "download and install nginx config from ihr360.com"
	downloadFile template-nginx-config.tar.gz nginx-config || return $?
	tar -xvf ${INSTALL_SPACE}/nginx-config/template-nginx-config.tar.gz -C /
	return 0
}

function installMysql(){
	colorEcho ${BLUE} "Installing MySQL..."
	if [[ -x `command -v mysql` ]];then echo "mysql alreay existed" && return 3;fi
	echo "deb http://security.ubuntu.com/ubuntu trusty-security main universe" > /etc/apt/sources.list.d/mysql.list
	echo 'mysql-server-5.6 mysql-server/root_password password root' | debconf-set-selections
        echo 'mysql-server-5.6 mysql-server/root_password_again password root' | debconf-set-selections
	apt-get update && apt-get install -y mysql-server-5.6
	colorEcho ${YELLOW} "backup mysql default config:/etc/mysql -> /etc/mysql.bak"
	mv /etc/mysql /etc/mysql.bak
	colorEcho ${BLUE} "download and install mysql config from ihr360.com"
	downloadFile template-mysql-config.tar.gz mysql-config || return $?
	tar -xvf ${INSTALL_SPACE}/mysql-config/template-mysql-config.tar.gz -C /
	systemctl enable mysql
	return 0
}

function installRedis(){
	colorEcho ${BLUE} "Installing Redis-server..."
	installSoftware docker.io || return $?
	docker run --name redis -p 6379:6379 -d --restart=always docker.ihr360.com/redis:4.0.13
	if [[ $? -eq 0 ]];then
		colorEcho ${BLUE} "Redis-server installed success!" && return 0
	else
		colorEcho ${RED} "Redis-server installed failed!" && return 1
	fi
	colorEcho ${BLUE} "Installing Redis-clients..."
	installSoftware redis-client
	return 0
}

function installMongodb(){
	colorEcho ${BLUE} "Installing Mongodb..."
	installSoftware docker.io || return $?
	rm ${INSTALL_SPACE}/mongo -rf
	rm /opt/docker/volumes -rf
	mkdir -p /opt/docker/volumes
	downloadFile mongo.tar.gz mongo || return $?
	tar -xvf ${INSTALL_SPACE}/mongo/mongo.tar.gz -C /opt/docker/volumes && mv /opt/docker/volumes/mongo /opt/docker/volumes/mongodb || return 1
	docker run -d  -v /opt/docker/volumes/mongodb:/data/db -v /tmp:/tmp --name mongo -p 27017:27017 --restart=always mongo:4.0 || return 1
	installSoftware mongodb-clients
	return 0
}

function templateDatabase(){
	colorEcho ${BLUE} "Downloading template databases..."
	downloadFile ${MAIN_DATABASES} templatedatabases || return $?
	downloadFile ${OTHER_DATABASES} templatedatabases || return $?
	downloadFile ${DATABASES_SCRIPTS} templatedatabases || return $?
		
	cd ${INSTALL_SPACE}/templatedatabases
	tar -xvf ${MAIN_DATABASES} || return $?
	tar -xvf ${OTHER_DATABASES} || return $?
	
	for SQLFILE in `ls *sql.gz`;do
		gzip -d $SQLFILE || echo "$SQLFILE ungzip failed"
	done

	if [[ ! -x `command -v mysql` ]];then echo "mysql not installed" && return 3;fi
	MYSQLSTATUS=`mysqladmin -uroot -proot ping 2>/dev/null`
	if [[ ${MYSQLSTATUS} = '' ]];then
		echo "mysql not alive" || return 1
	fi
	bash ${DATABASES_SCRIPTS} || return $?
	return 0
}

function help(){

	echo "nothing"
}

function updateEnvironmentInit(){
	colorEcho ${BLUE} "Delete old publish scripts..."	
	rm /data/scripts/publish -rf
	colorEcho ${BLUE} "Download publish scripts..."
	downloadFile ${PUBLISH_SCRIPTS} updateScripts || return $?
	tar -xvf ${INSTALL_SPACE}/updateScripts/${PUBLISH_SCRIPTS} -C /data/scripts >/dev/null 2>&1
	downloadFile ${UPDATE_LISTS} updateENV || return $?	
	colorEcho ${BLUE} "Create update log file..."
	touch ${CURRENT_SPACE}/pullPrivateImages.log
        touch ${CURRENT_SPACE}/restartPrivateContainers.log

}

function createPrivateScripts(){
	colorEcho ${BLUE} "create private cloud publish scripts."
	rm /data/scripts/publish/private-cloud-publish -rf
	mkdir -p /data/scripts/publish/private-cloud-publish
	cp /data/scripts/publish/*.sh /data/scripts/publish/private-cloud-publish
	cd /data/scripts/publish/private-cloud-publish
	UPDATE_SCRIPTS=`ls *.sh | grep -vE "env.sh|backup-running-images.sh|template.sh"`
	for SCRIPT in ${UPDATE_SCRIPTS};do
		count=0
		cp ${SCRIPT} pull-${SCRIPT}
                cp ${SCRIPT} start-${SCRIPT}
                rm ${SCRIPT}

		sed -i '/docker pull/d' start-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi
                sed -i '/pull failed/d' start-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi

                sed -i '/docker stop/d' pull-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi
                sed -i '/docker rm/d'   pull-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi
                sed -i '/start failed/d' pull-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi
                sed -i '/docker run/d' pull-${SCRIPT}
                if [ $? -ne 0 ];then count++;fi

		if [ $count -ne 0 ];then
                        colorEcho ${RED} "${SCRIPT} create publish error!"
                fi
	done
}

function pullPrivateImages(){
	cd /data/scripts/publish/private-cloud-publish
	if [[ ! -f $CURRENT_SPACE/$UPDATE_LISTS ]];then colorEcho ${RED} "updateList not existed,please Download Update List and Scripts...";fi
	UPDATE_APPS=`cat ${CURRENT_SPACE}/${UPDATE_LISTS}`
	for APP in ${UPDATE_APPS};do
		app_name=`echo ${APP} | awk -F ":" '{ print $1}'`
                app_version=`echo ${APP} | awk -F ":" '{ print $2}'`

		echo "---> $app_name will be pull with version $app_version..."
		if [ ! $app_version ];then
                        colorEcho ${RED} "[ERROR] $app_name no version exist !" 
                        echo "[ERROR] $app_name no version exist !" >> ${CURRENT_SPACE}/pullPrivateImages.log
                        continue
                fi

		if [ -f pull-$app_name.sh ];then
                        bash pull-$app_name.sh $app_version
                        if [ $? -eq 0 ];then
                                colorEcho ${BLUE} "[INFO] ${app_name} pull success." 
                                echo "[INFO] ${app_name} pull success." >> ${CURRENT_SPACE}/pullPrivateImages.log
                        else
                                colorEcho ${YELLOW} "[ERROR] ${app_name} pull error." 
                                echo "[ERROR] ${app_name} pull error." >> ${CURRENT_SPACE}/pullPrivateImages.log
                        fi
                else
                        colorEcho ${RED} "[ERROR] $app_name no publish_scripts exist !" 
                        echo "[ERROR] $app_name no publish_scripts exist !" >> ${CURRENT_SPACE}/pullPrivateImages.log
                fi
	done

}

function startPrivateContainers(){
	cd /data/scripts/publish/private-cloud-publish
	if [[ ! -f ${CURRENT_SPACE}/${UPDATE_LISTS} ]];then colorEcho ${RED} "updateList not existed,please Download Update List and Scripts...";fi
	UPDATE_APPS=`cat ${CURRENT_SPACE}/${UPDATE_LISTS}`
	for APP in ${UPDATE_APPS};do
		app_name=`echo ${APP} | awk -F ":" '{ print $1}'`
                app_version=`echo ${APP} | awk -F ":" '{ print $2}'`

		echo "---> $app_name will be restart with version $app_version..."
		if [ ! $app_version ];then
                        colorEcho ${RED} "[ERROR] $app_name no version exist !" 
                        echo "[ERROR] $app_name no version exist !" >> ${CURRENT_SPACE}/startPrivateContainers.log
                        continue
                fi

		if [ -f start-$app_name.sh ];then
                        bash start-$app_name.sh $app_version
                        if [ $? -eq 0 ];then
                                colorEcho ${BLUE} "[INFO] ${app_name} restart success." 
                                echo "[INFO] ${app_name} restart success." >> ${CURRENT_SPACE}/startPrivateContainers.log
                        else
                                colorEcho ${YELLOW} "[ERROR] ${app_name} restart error." 
                                echo "[ERROR] ${app_name} restart error." >> ${CURRENT_SPACE}/startPrivateContainers.log
                        fi
                else
                        colorEcho ${RED} "[ERROR] $app_name no publish_scripts exist !" 
                        echo "[ERROR] $app_name no publish_scripts exist !" >> ${CURRENT_SPACE}/startPrivateContainers.log
                fi
	done
	
}

function stop_migrate_and_datafix(){

        FIX_LIST=`docker ps --format "{{.Names}}" | grep -E "migrate|datafix"`
        #echo $LIST
        for migrate_and_datafix in $FIX_LIST;do
        {
            #echo $i
            docker stop $migrate_and_datafix
        } &
        done
        wait

}

function displayMenu(){

	DISPLAY=$1
	case $DISPLAY in
		main)
cat << EOF
---------------------------------------------------------------
|******* Private Cloud Install or Update Scriptes v2.0 *******|
---------------------------------------------------------------
*   `echo -e "\033[35m 1)Private Cloud Environment Install\033[0m"`
*   `echo -e "\033[35m 2)Private Cloud Environment Update\033[0m"`
*   `echo -e "\033[35m 3)Scripts Documents\033[0m"`
*   `echo -e "\033[35m 0)quit\033[0m"`
EOF
		 ;;
		install)
cat << EOF
-------------------------------------------------------------------
|******* Installation menu! Please Enter Your Choice:[1-9] *******|
-------------------------------------------------------------------
*   `echo -e "\033[35m 1)Install Server Init Config\033[0m"`
*   `echo -e "\033[35m 2)Install Nginx\033[0m"`
*   `echo -e "\033[35m 3)Install Mysql-Server-5.6\033[0m"`
*   `echo -e "\033[35m 4)Install Redis for docker\033[0m"`
*   `echo -e "\033[35m 5)Install Mongo for docker\033[0m"`
*   `echo -e "\033[35m 6)Install Template databases \033[0m"`
*   `echo -e "\033[35m 9)Install All Environment\033[0m"`
*   `echo -e "\033[35m 0)Return main menu\033[0m"`
EOF
		 ;;
		update)
cat << EOF
-------------------------------------------------------------
|******* Update menu! Please Enter Your Choice:[1-9] *******|
-------------------------------------------------------------
*   `echo -e "\033[35m 1)Download Update List and Scripts\033[0m"`
*   `echo -e "\033[35m 2)Create UpdateScripts\033[0m"`
*   `echo -e "\033[35m 3)Pull Docker Images\033[0m"`
*   `echo -e "\033[35m 4)Restart Docker Container\033[0m"`
*   `echo -e "\033[35m 5)Stop All Migrate and Datafix\033[0m"`
*   `echo -e "\033[35m 0)Return main menu\033[0m"`
EOF
		 ;;
		*)
		 echo ERROR && return 1
		 ;;
	esac
}

function installMenu(){

displayMenu install
while true;do
	read -p "--> please input install optios[1-9]:" INSTALLOPTION
	case $INSTALLOPTION in
		1)
		 serverInit
		 if [[ $? -ne 0 ]];then echo "Server init failed";fi
		 ;;
		2)
		 installNginx
		 if [[ $? -ne 0 ]];then echo "install nginx failed";fi
		 ;;
		3)
		 installMysql
		 if [[ $? -ne 0 ]];then echo "install mysql failed";fi
		 ;;
		4)
		 installRedis
		 if [[ $? -ne 0 ]];then echo "install redis failed";fi
		 ;;
		5)
		 installMongodb
		 if [[ $? -ne 0 ]];then echo "install mongo failed";fi
		 ;;
		6)
		 templateDatabase
		 if [[ $? -ne 0 ]];then echo "install template databases failed";fi
		 ;;
		9)
		 ;;
		0)
		 clear
		 displayMenu main
		 break
		 ;;
		*)
		 clear
		 echo -e "\033[31mYour Enter the wrong,Please input again Choice:[1-9]\033[0m"
		 displayMenu install
		 ;;
	esac	
done
}

function updateMenu(){

displayMenu update
while true;do
        read -p "--> please input update optios[1-9]:" UPDATEOPTION
        case $UPDATEOPTION in
                1)
		 updateEnvironmentInit
                 ;;
                2)
		 createPrivateScripts
                 ;;
                3)
		 pullPrivateImages
                 ;;
                4)
		 startPrivateContainers
                 ;;
                5)
		 stop_migrate_and_datafix
                 ;;
                0)
                 clear
                 displayMenu main
		 break
                 ;;
		*)
		 clear
		 echo -e "\033[31mYour Enter the wrong,Please input again Choice:[1-9]\033[0m"
                 displayMenu update
        esac
done
}

clear
displayMenu main
while true;do
	read -p "--> please input optios[1-9]:" MENUOPTION
	case $MENUOPTION in
		1)
		 clear
		 installMenu
		 ;;
		2)
		 clear
		 updateMenu
		 ;;
		3)
		 clear
		 help
		 ;;
		0)
		 clear
		 break
		 ;;
		*)
		 clear
		 echo -e "\033[31mYour Enter a number Error,Please Enter again Choice:[1-9]
: \033[0m"
		 displayMenu main
	esac
done
