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
    while read line;do
        pod_name=`kubectl get pods -n $ns | grep $app | awk '{print $1}'`
        status=`kubectl get pods -n $ns | grep $app | awk '{print $3}'`
    done</tmp/1.txt
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
-------------------------------------------------------
菜单栏(函数)
1.apply_pod  更新应用(包含ver_chk)
    ver_chk    检查web的app_version和yaml中的image_version
2.pod_status 检查应用(pod)的状态
3.log_cmd    查看日志
--------------------------------------------------------
流程:
更新应用, 1分钟 3分钟 5分钟,检查pod状态

------------------------------------------------------
2.检查yaml中的image版本和是否一致
    y)
        输出 app_name web_docker_ersion yaml_docker_version
            input是否要按顺序apply *.yaml
                y)
                    kubectl apply -f ,sleep 5
                n)
                    exit
    n)
        输出 app_name web_docker_ersion yaml_docker_version
        
