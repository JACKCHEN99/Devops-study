#!/bin/bash
[ -f /etc/init.d/functions ] && source /etc/init.d/functions
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

host_ip_last=`ifconfig ens160 | awk -F '[ .]*' '/inet/{print $6}'`
if [ $host_ip_last -eq 229 ];then ns=uatstable;elif [ $host_ip_last -eq 186 ];then ns=uat;fi
IFS=";"

apply_pod(){
    app=`echo $yaml | awk '{print $1}'`
    cd /data/script/k8s-$ns/yaml
    while read yaml;do
        kubecl apply -f ${app}.yaml
        sleep 3
    done<1.txt
}

ver_chk(){
    
}

pod_status(){
    while read line;do
        pod_name=`kubectl get pods -n $ns | grep $app | awk '{print $1}'`
        status=`kubectl get pods -n $ns | grep $app | awk '{print $3}'`
    
        kubectl get pods -n $ns | grep $app &>/dev/null
        if [[ $? -eq 0 ]];then
            if [[ $status == Running ]];then
                echo "$app => ${status}, 名称 ${pod_name}"
            else
                colorEcho $YELLOW "$app => ${status}, 名称 ${pod_name}"
            echo "    请查看日志: kubectl logs -n $ns --tail 500 $pod_name"
            fi
        else
            colorEcho $RED "$app is not running!"
        fi
    done</tmp/1.txt
}




# file format:
# app_name;image_version;source;health_check_site
