#!/usr/bin/sh
# 作用: 用于修稿主机名和密码
# 用法: sh hostname_ip.sh  你的主机名  主机IP最后一个点后面的数字(比如192.168.11.xx)
source /etc/init.d/functions
if [ $# -ne 2 ];then
echo "/bin/sh $0 New hostname New IP address"
exit 1
fi
hostnamectl set-hostname $1
if [ $? -eq 0 ];then
    action "hostname update Successfull." /bin/true
else
    action "hostname update Failed." /bin/false
fi
sed -ri "/^IPA/s#(.*\.).*#\1$2\"#g" /etc/sysconfig/network-scripts/ifcfg-eth[01]
if [ $? -eq 0 ];then
    action "IP update Successfull." /bin/true
    systemctl restart network
else
    action "IP update Failed！" /bin/false
fi
bash