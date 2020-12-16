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

while read line;do
    num_column=`echo $line | awk '{print NF}'`
    app=`echo $line | awk '{print $1}'`
    ver_cmd=`echo $line |  awk '{$1=""; print $0}'`

    kubectl get pods -n $1 | grep $app &>/dev/null
    if [[ $? -eq 0 ]]; then
        pod_name=`kubectl get pods -n $1 | grep $app | awk '{print $1}'`
        status=`kubectl get pods -n $1 | grep $app | awk '{print $3}'`
            if [[ $status == Running ]];then
                echo "$app => ${status}, 名称 ${pod_name}"
                #printf "%-15s %-5s %-8s %-6s %-15s\n"  $app => ${status} 名称 ${pod_name}
            else
                colorEcho $YELLOW "$app => ${status}, 名称 ${pod_name}"
            fi
    else
        colorEcho $RED "$app 没有运行"
    fi
done<1.txt
