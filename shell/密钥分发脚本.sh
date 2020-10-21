#!/bin/bash
# 功能: 实现当前主机免密登录其它主机(自己定义)
# 用法: 如果当前主机为生成密钥对, 需要手动按两次enter, 来跳过ssh-keygen的交互
#         - 主机列表需要自己修改$ip, 如果有很多主机, 也可以自己修改: 把ip写入文件, 通过 while read line读入
#         - 修改其它主机的密码pass(需要是一样的)
#         - 这是以root用户写的, 普通用户权限可能不够

# 检查当前主机是否安装expect命令, 没有则安装
rpm -q expect || echo '正在安装expect' ; yum install -y expect &>/dev/null

# 检查当前主机是否有密钥对, 没有则创建. -f 指定私钥目录 -P 为什么加了这个参数, 每次免密登录都要求输入这个免密, 而且免密也是失效的
#[ -s ~/.ssh ] || ssh-keygen -t rsa -f ~/.ssh/id_rsa -P “”   # 免输入创建密钥对
[ -s ~/.ssh ] || ssh-keygen -t rsa -f ~/.ssh/id_rsa                 # -P 有问题, 暂时还是改为手动吧

pass=1       # 其他主机的密码  
hostname=root
# 要分发密钥的ip, 如果内外网都要连接的话, 最好都写上
ip='10.0.0.91 10.0.0.8 172.16.1.91 172.16.1.8'      
for i in $ip;do
expect << EOF
    spawn ssh-copy-id -i /root/.ssh/id_rsa.pub $hostname@$i
    expect {
        "yes/no" {send "yes\r";exp_continue}
        "*assword" {send "$pass\n"}
    }
    expect eof 
EOF
done