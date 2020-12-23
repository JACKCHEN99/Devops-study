#! /bin/bash

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

function updateEnvironmentInit(){
    if [ ! -d "/data/backup" ]; then
        mkdir -p /data/backup
    fi
    if [ -f '/data/backup/env.sh' ]; then
        rm /data/backup/env.sh -rf
    fi
    cp /data/scripts/publish/env.sh /data/backup/
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
    if [ -f  '/data/scripts/publish/env.sh' ]; then
        rm /data/scripts/publish/env.sh -rf
    fi
    cp /data/backup/env.sh /data/scripts/publish/
    cp /data/scripts/publish/*.sh /data/scripts/publish/private-cloud-publish
    cd /data/scripts/publish/private-cloud-publish
    UPDATE_SCRIPTS=`ls *.sh | grep -vE "env.sh|backup-running-images.sh|template.sh"`
    for SCRIPT in ${UPDATE_SCRIPTS}; do
        cp ${SCRIPT} pull-${SCRIPT}
        cp ${SCRIPT} start-${SCRIPT}
        rm ${SCRIPT} -rf
        sed -i '/docker stop/d' pull-${SCRIPT}
        if [ $? -ne 0 ]; then 
            colorEcho ${RED} "create pull-${SCRIPT} error!"
        fi 
        sed -i '/docker rm/d' pull-${SCRIPT}
        if [ $? -ne 0 ]; then
            colorEcho ${RED} "create pull-${SCRIPT} error!"
        fi
        sed -i '/start failed/d' pull-${SCRIPT}
        if [ $? -ne 0 ]; then
            colorEcho ${RED} "create pull-${SCRIPT} error!"
        fi
        sed -i '/docker run/d' pull-${SCRIPT}
        if [ $? -ne 0 ]; then
            colorEcho ${RED} "create pull-${SCRIPT} error!"
        fi


        sed -i '/docker pull/d' start-${SCRIPT}
        if [ $? -ne 0 ]; then
            colorEcho ${RED} "create start-${SCRIPT} error!"
        fi
        sed -i '/pull failed/d' start-${SCRIPT}
        if [ $? -ne 0 ]; then
            colorEcho ${RED} "create start-${SCRIPT} error!"
        fi
    done 
}


function getAppVersinList(){
    cd  ${CURRENT_SPACE}/
    wget https://callback.ihr360.com/download/get_version.py > /dev/null 2>&1
    if [ -f update_app_version.txt ]; then
        rm update_app_version.txt -rf
    fi
    python  get_version.py | grep -vE 'None' > update_app_version.txt
    sed -i '1d' update_app_version.txt
    mv private_update.list private_update.list.bak 
    mv update_app_version.txt private_update.list 
}


function pullPrivateImages(){
    cd /data/scripts/publish/private-cloud-publish
    if [ !-f $CURRENT_SPACE/$UPDATE_LISTS ]; then 
        colorEcho ${RED} "updateList not existed,place Download Update List and Scripts..."
    fi
    UPDATE_APPS=`cat ${CURRENT_SPACE}/${UPDATE_LISTS}`
    for APP in ${UPDATE_APPS};do
        app_name=`echo ${APP} | awk -F ':' '{print $1}'`
        app_version=`echo ${APP} | awk -F ':' '{print $2}'`
        echo "---> $app_name will be pull with version $app_version..."
        if [ ! $app_version ]; then
            colorEcho ${RED} "[ERROR] $app_name no version exist !"
            echo "[ERROR] $app_name no version exist !" >> ${CURRENT_SPACE}/pullPrivateImages.log
            continue
        fi

        if [ -f pull-$app_name.sh ]; then
            bash pull-$app_name.sh $app_version
            if [ $? -eq 0 ]; then
                colorEcho ${BLUE} "[INFO] ${app_name} pull sucess."
                echo "[INFO] ${app_name} pull sucess." >> ${CURRENT_SPACE}/pullPrivateImages.log
            else
                colorEcho ${RED} "[ERROR] ${app_name} pull error."
                echo "[ERROR] ${app_name} pull error." >> ${CURRENT_SPACE}/pullPrivateImages.log
            fi
        else
            colorEcho ${RED} "[ERROR] ${app_name} no publish_scripts exist !"
            echo "[ERROR] ${app_name} no publish_scripts exist !" >> ${CURRENT_SPACE}/pullPrivateImages.log
        fi
    done
}


function restartPrivateContainers(){
    cd /data/scripts/publish/private-cloud-publish
    if [ !-f ${CURRENT_SPACE}/${UPDATE_LISTS} ]; then
        colorEcho ${RED} "updateList not existed,place Download Update List and Scripts..."
    fi
    UPDATE_APPS=`cat ${CURRENT_SPACE}/${UPDATE_LISTS}`
    for APP in ${UPDATE_APPS}; do
        app_name=`echo ${APP} | awk -F ':' '{print $1}'`
        app_version=`echo ${APP} | awk -F ':' '{print $2}'`
        echo "--->$app_name will be pull with version $app_version..."
        if [ ! $app_version ]; then
            colorEcho ${RED} "[ERROR] $app_name no version exist !"
            echo "[ERROR] $app_name no version exist !" >> ${CURRENT_SPACE}/restartPrivateContainers.log
            continue
        fi

        if [ -f start-$app_name.sh ]; then
            bash start-$app_name.sh $app_version
            if [ $? -eq 0 ]; then
                colorEcho ${BLUE} "[INF0] ${app_name} start sucess."
                echo "[INFO] ${app_name} start sucess." >> ${CURRENT_SPACE}/restartPrivateContainers.log
            else
                colorEcho ${RED} "[ERROR] ${app_name} start error."
                echo "[ERROR] ${app_name} start error." >> ${CURRENT_SPACE}/restartPrivateContainers.log
            fi
        else
            colorEcho ${RED} "[ERROR] ${app_name} no publish_scripts exist !"
            echo "[ERROR] ${app_name} no publish_scripts exist !" >> ${CURRENT_SPACE}/restartPrivateContainers.log
        fi
    done
}


function stopAllMigrateDatafix(){
    DATA_APPS=`docker ps --format "{{.Names}}" | grep -E "migrate|datafix"`
    for migrate_datafix_app in ${DATA_APPS}; do
    {
        docker stop $migrate_datafix_app
    } &
    done
    wait
    endTime=`date +%s`
    echo "总共耗时:" $(($endTime-$beginTime)) "秒"

}



function getHealthCheckList(){
    cd  ${CURRENT_SPACE}/
    wget https://callback.ihr360.com/download/check.py
    if [ -f local_app_name.txt ]; then
        rm local_app_name.txt -rf
    fi
    docker ps | grep -vE 'mongo|redis|ID|kafka|zookeeper|migrate|datafix' | awk -F ' ' '{print $NF}' > local_app_name.txt
    if [ -f update_app_name.txt ]; then
        rm update_app_name.txt -rf
    fi
    cat local_app_name.txt | xargs -i grep {} private_update.list.bak > update_app_name.txt
    mv privata_update.list private_update.list.bak2
    mv update_app_name.txt private_update.list
    if [ -f local_app_name.txt ]; then
        rm local_app_name.txt -rf
    fi
    if [ -f update_app_name.txt ]; then
        rm update_app_name.txt -rf
    fi
    python check.py | grep -vE ok
}


function  mysqlSetCrontab(){
    if [ ! -d "/data/backup" ]; then
        mkdir -p /data/backup
    fi
    cd  /data/backup/
    if [ ! -f "private_cloud_mysql_backup.sh" ]; then
        wget  https://callback.ihr360.com/download/private_cloud_mysql_backup.sh   > /dev/null 2>&1
    fi
    echo "0 3 * * * bash /data/backup/private_cloud_mysql_backup.sh" >> /var/spool/cron/crontabs/root
    colorEcho ${BLUE} "crontab set seccuss..."
}


cat<<EOF
********************************************************************
|--------- Update server! Please Enter Your Choice:[1-9] ----------|
********************************************************************
*   `echo -e "\033[35m 1)Download Update List and Scripts\033[0m"`
*   `echo -e "\033[35m 2)Create UpdateScripts\033[0m"`
*   `echo -e "\033[35m 3)Get Location Server Update List\033[0m"`
*   `echo -e "\033[35m 4)Pull Docker Images\033[0m"`
*   `echo -e "\033[35m 5)Restart Docker Container\033[0m"`
*   `echo -e "\033[35m 6)Stop All Migrate and Datafix\033[0m"`
*   `echo -e "\033[35m 7)Get Health Check List And Health Check\033[0m"`
*   `echo -e "\033[35m 8)Set Mysql Backup and Crontab\033[0m"`
*   `echo -e "\033[35m 0)Exit\033[0m"`
EOF

while true
  do
    read -p "--->Update Operate---Please Enter Your Choice:[1-9]：" key
    case $key in
            1)
            updateEnvironmentInit
            ;;
            2)
            createPrivateScripts
            ;;
            3)
            getAppVersinList
            ;;
            4)
            pullPrivateImages
            ;;
            5)
            restartPrivateContainers
            ;;
            6)
            stopAllMigrateDatafix
            ;;
            7)
            getHealthCheckList
            ;;
            8)
            mysqlSetCrontab
            ;;
            0)
            break
    esac
done
