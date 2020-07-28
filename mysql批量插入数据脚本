#!/bin/bash
# 计算脚本运行时间, 开始时间
start_time=`date --date='0 days ago' "+%Y-%m-%d %H:%M:%S"`

# 用户输入/显示信息
echo "欢迎来到mysql批量插入数据脚本! "
read -p "准备插入数据的mysql所在主机(${host}/52...):" host
read -p "一共多少条数据: " num1
read -p "每秒插入多少条: " num2
time=$(echo "print ${num1}.0/${num2}" | python)
sleep_time=$(echo "print 1.0/${num2}" | python)
echo "睡眠时间 $sleep_time"
echo "即将在172.16.1.${host}主机test库下的employee表, 插入${num1}条数据, 约需要: $time s, 请耐心等待... "

# 检测是否安装mkpasswd, 未安装则安装(生成用户名需要使用)
mkpasswd &> /dev/null
if [[ $? -ne 0 ]]; then
    yum install -y expect &\
fi

# 定义创建表结构函数
create_table() {
    mysql -uroot -h 172.16.1.${host} -e " \
    use test; \
    create table employee(  \
    id int unsigned primary key auto_increment,  \
    name varchar(20) not null,  \
    gender enum('w','m'),  \
    age tinyint unsigned not null,  \
    birthday datetime,  \
    salary int unsigned not null  \
    );"
}

# 检测所在mysql, 是否有test库, test库下是否有employee表
mysql -uroot -h 172.16.1.${host} -e "use test" &>/dev/null
if [ $? -eq 1 ];then
    mysql -uroot -h 172.16.1.${host} -e "create database test" &>/dev/null
    create_table
else
    mysql -uroot -h 172.16.1.${host} -e "use test;desc employee" &>/dev/null
    if [ $? -eq 1 ];then
        create_table
    fi
fi

# 批量插入数据主程序
i=1
while [ $i -le $num1 ]
do
    # 定义变量
    name=$(mkpasswd -l 8 -c 8 -C 0 -s 0 -d 0)
    sj=$(echo $[$RANDOM%2])
    if [ $sj -eq 0 ];then
        gender='m'
    else
        gender='w'
    fi
    age=$(echo $[$RANDOM % 101 + 1])
    birthday=$(date +"%Y%m%d" -d "-$(shuf -i 1000-15000 -n 1) days")
    salary=$(echo $RANDOM)

    # 插入数据命令
    mysql -uroot -h 172.16.1.${host} -e "insert into test.employee(name,gender,age,birthday,salary) values ('${name}','${gender}',${age},${birthday},${salary})"
    let i++
    # 睡眠, 大概控制每秒插入数据的数量
    sleep $sleep_time
done

# 计算脚本运行时间, 结束时间
finish_time=`date --date='0 days ago' "+%Y-%m-%d %H:%M:%S"`
duration=$(($(($(date +%s -d "$finish_time")-$(date +%s -d "$start_time")))))
echo "实际用时: $duration"
