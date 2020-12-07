#!/bin/bash
menu() {
cat<<EOF
#------------------------
1. 菜单
2. 访问排行前10ip
#------------------------
EOF
}

menu
while true;do
read -p "请输入菜单中的编号: " num
if [[ ! $num =~ ^[0-9]+$ ]];then
    echo "必须要输入数字!"
    exit
fi

case $num in
    1)
        clear
        menu
        ;;
    2)
        clear
        echo "访问排行前10ip: "
        grep -rn   access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 10
        
esac
done


通过日志查看当天 ip 连接数，统计 ip 地址的总连接数

echo "访问量最高的10个ip地址: "
cat access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head

echo "访问次数最多的10个Url请求: "
cat access.log | awk -F "\"" '{print $(NF-5)}' | sort | uniq -c | sort -nr | head 

echo "排名前10的多的 UserAgent: "
cat access.log | awk -F "\"" '{print $(NF-3)}' | sort | uniq -c | sort -nr | head