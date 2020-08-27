#!/bin/bash
# func: Testing the survival of a host
# desc: 
for i in {1..255};do
    ip=172.16.1.$i
    # 1.&=>Concurrent execution,faster  2.host that cannot be pinged can not output
    (ping -c1 -W1 $ip &>/dev/null && echo -e "\033[42;37m Host $ip connent \033[0m" || echo "Host $ip not connection") &
    sleep 0.01
done
# in case some output format error
wait