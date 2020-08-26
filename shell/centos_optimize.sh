#!/bin/bash
# 更换yum源为国内
rm -rf /etc/yum.repos.d/*
curl -s -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
curl -s -o  /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all

# 安装常用软件
yum -y install tree nmap sysstat lrzsz telnet bash-completion bash-completion-extras vim lsof net-tools rsync ntpdate nfs-utils wget

# 内核优化
cat >>/etc/sysctl.conf<<EOF
net.ipv4.tcp_fin_timeout = 2
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.ip_local_port_range = 4000 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
EOF
sysctl  -p

# 别名/环境变量优化
cat>>/etc/profile.d/color.sh<<EOF
alias ll='ls -l --color=auto --time-style=long-iso'
# PS1请用单引号
PS1='\[\e[37;1m\][\[\e[32;1m\]\u\[\e[37;1m\]@\h \[\e[36;1m\]\w\[\e[37;1m\]]\[\e[32;1m\]$ \[\e[0m\]'
# PS1='\[\e[32;1m\]\u@\h\[\e[37m\]:\[\e[36;1m\]\w\[\e[37;1m\]\$\[\e[0m\] '    #可选样式2
export HISTTIMEFORMAT='%F-%T '
EOF
source  /etc/profile

# 禁止DNS反向解析
sed -i  's#^\#UseDNS.*#UseDNS no#g'  /etc/ssh/sshd_config
# 禁止GSS认证，优化连接速度
sed -i  's#^GSSAPIA.*#GSSAPIAuthentication no#g'  /etc/ssh/sshd_config
# 重启生效
systemctl  restart  sshd

# 关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
# 关闭selinux
sed -i '/^SELINUX=enforcing/cSELINUX=disabled' /etc/sysconfig/selinux
sed -i '/^SELINUX=enforcing/cSELINUX=disabled' /etc/selinux/config
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable  NetworkManager

# 同步系统时间
[ -f /var/spool/cron/root ] || touch /var/spool/cron/root
cat>>/var/spool/cron/root<<EOF
*/3 * * * * /usr/sbin/ntpdate  ntp1.aliyun.com &>/dev/null
EOF

# 修改主机名/ip脚本
cat>/root/hostname_ip.sh<<"EOF"
#!/usr/bin/sh
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
EOF