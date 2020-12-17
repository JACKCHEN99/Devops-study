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

[ $# -ne 1 ] && echo "请加上namespace";exit


IFS=";"
while read line;do
    num_column=`echo $line | awk '{print NF}'`
    app=`echo $line | awk '{print $1}'`
    chk_cmd=`echo $line |  awk '{$1=""; print $0}'`
    pod_name=`kubectl get pods -n $1 | grep $app | awk '{print $1}'`
    status=`kubectl get pods -n $1 | grep $app | awk '{print $3}'`

    kubectl get pods -n $1 | grep $app &>/dev/null
    if [[ $? -eq 0 ]]; then
        # pods正常running
        if [[ $status == Running ]];then
            echo "$app => ${status}, 名称 ${pod_name}"
            if [ $num_column -eq 1 ];then
                echo '    echo "没有注释"'
            else
                for cmd in $chk_cmd;do

                done
            fi
        # pod状态为非running
        else
            colorEcho $YELLOW "$app => ${status}, 名称 ${pod_name}"
        echo "    请查看日志: kubectl logs -n $1 --tail 500 $pod_name"
        fi
    else
        # pod没起来
        colorEcho $RED "$app 没有运行"
    fi
done<1.txt

