#!/bin/bash
>result.txt

chk_health() {
    while read line;do
        kubectl get pods -n $1 | grep $line &>/dev/null
        if [[ $? -eq 0 ]]; then
            pod_name=`kubectl get pods -n $1 | grep $line | awk '{print $1}'`
            pod_status=`kubectl get pods -n $1 | grep $line | awk '{print $3}'`
            kubectl get svc -n $1 | grep $line &>/dev/null
            [ $? -eq 0 ] && echo "$pod_name $pod_status svc_yes" >> result.txt || echo "$pod_name $pod_status svc_no" >> result.txt
        else
            ls /data/script/k8s-uatstable/yaml/${line}.yaml &>/dev/null
            [ $? -eq 0 ]  && echo "$line not_found yes_yaml" >> result.txt || echo "$line not_found no_yaml" >>result.txt
        fi
    done< $1.txt
    echo
    echo "$1 brand pod check result:"
    echo "++++++++++++++++exist++++++++++++++++++"
    cat result.txt | awk '/svc/{print $1,$2,$3}' | column -t
    echo "+++++++++++++++++not exist++++++++++++++++++"
    #cat result.txt | grep 'no_found'
    cat result.txt | awk '/not_found/{print $1,$3}' | sort -rk 2 | column -t
    echo
}

chk_health $1
