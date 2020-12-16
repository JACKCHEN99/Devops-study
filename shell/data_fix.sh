#!/bin/bash
[ -f /etc/init.d/functions ] && source /etc/init.d/functions

apps=
ns=$1


for pod in $apps;do
    kubectl get pods -n $ns | grep $i &>/dev/null
    if [ &? -eq 0 ];then
        echo $app
    else

    fi    
done
