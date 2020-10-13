#!/bin/bash
#!/bin/bash
#判断用户是否为超级管理员root用户
if [ $USER != "root"  -o  $UID -ne  0  ];then
    echo "当前用户${USER}对此脚本${0}没有权限执行！"
    exit
fi
#提示用户输入创建用户的前缀
read -p "请输入你要创建用户的前缀[前缀必须是字母组成的]：" Qz
#判断用户输入的前缀是否为字母组成的
if [[ ! $Qz =~ ^[a-Z]+$ ]];then
    echo "你输入的不符合要求！前缀必须是由字母组成的！"
    exit
fi
#提示用户输入创建用户后缀，即数量
read -p "请输入你要创建用户的数量：" Num
#判断用户输入的数量是否为数字
if [[ ! $Num =~ ^[0-9]+$ ]];then
    echo "你输入的不符合要求！创建用户的数量必须为正整数！"
    exit
fi
#提示用户接下来要创建的用户列表
echo "接下来你要创建的用户为：${Qz}1..${Qz}${Num}"
read -p "你是否确定要进行创建这些用户[y/n]：" Confirm
#编写case语句
case $Confirm in
    y|Y|yes|Yes)
        echo "你选择了要进行创建以上用户！"
        for i in $(seq $Num)
        do
            #将用户的前缀和后缀组合在一起
            User=${Qz}${i}
            #判断用户是否存在
            id $User &>/dev/null
            if [ $? -eq 0 ];then
                echo "用户${User}已经存在！无需再次进行创建！"
            else
                Pass=$(mkpasswd  -l 24 -s 6 -d 6 -c 6 -C 6)
                useradd $User &>/dev/null && echo $Pass | passwd --stdin $User &>/dev/null
                if [ $? -eq 0 ];then
                    echo "用户${User}创建成功！密码设置成功！密码文件为：user_pass.txt"
                    echo -e "User: $User\tPass: $Pass" >> user_pass.txt
                else
                    echo "用户${User}创建失败！"
                fi
            fi
        done
        ;;
    n|N|No|no)
        echo "你选择不进行创建这些用户！脚本程序退出！"
        exit
        ;;
    *)
        echo "你输入不符合要求！请重新输入！"
        exit
esac
#给密码文件设置只有管理员可读权限
chmod 400  user_pass.txt
