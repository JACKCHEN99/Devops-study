#!/bin/bash
#nginx_file=/root/beta.ihr360.com.access.log
nginx_file=/root/access.log
menu() {
cat<<EOF
#------------------------------------
1. 菜单
#------------------------------------
统计 PV,UV 数
2. 统计所有的PV数
3. 统计当天的PV数
4. 统计指定某一天的PV数
5. 统计 UV
6. 统计指定某一天的UV
#------------------------------------
7. 统计IP访问量（独立ip访问数量）
8. 访问最频繁的前10个IP
#------------------------------------
其它
9. 查看访问最频繁的页面 (TOP10)
10. 状态码数量（多到少排序）
#------------------------------------
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
        echo "统计所有的PV数: "
        cat $nginx_file | wc -l
	menu
        ;;
    3)
        clear
        echo "统计当天的PV数: "
        cat $nginx_file | sed -n /`date "+%d\/%b\/%Y"`/p | wc -l
        ;;
    4)
        clear
        echo "统计指定某一天的PV数： "
        cat $nginx_file | sed -n '/26\/Sep\/2019/p' | wc -l
        ;;
    5)
        clear
        echo "统计UV: "
        cat $nginx_file | sort | uniq -c |wc -l
        ;;
    6)
        clear
        echo "统计指定某一天的UV: "
        cat $nginx_file | grep "07/Apr/2019" | awk '{print $1}' access.log|sort | uniq -c |wc -l
        ;;
    7)
        clear
        echo "统计IP访问量（独立ip访问数量）: "
        cat $nginx_file | sort -n | uniq | wc -l
        ;;
    8)
        clear
        echo "访问最频繁的前10个IP: "
        awk '{print $1}' $nginx_file | sort -n |uniq -c | sort -rn | head -n 10
        ;;

    9)
        clear
        echo "查看访问最频的10个url: "
        cat $nginx_file | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 10
        ;;

    10)
        clear
        echo "状态码数量（多到少排序）： "
        cat $nginx_file | awk '{print $9}' | sort | uniq -c | sort -rn     
esac
done
