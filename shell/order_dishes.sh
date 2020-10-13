#!/bin/bash
menu() {
cat<<EOF
#######################
1. 夫妻肺片 48元
2. 五香牛肉 68元 
3. 蒜泥黄瓜 28元 
4. 糖醋鲤鱼 78元 
5. 红烧排骨 98元 
6. 红烧猪蹄 88元 
7. 海鲜大咖 298元 
8. 澳洲龙虾 998元 
9. 结束点菜 
#######################
EOF
}

>cai.txt
echo "欢迎来到xxx大酒店！很高兴为你服务！"

while true
do
    menu
    read -p "请开始你的点餐：" Num

    if [[ ! $Num =~ ^[1-9]$ ]];then
        echo "你点菜！本酒店没有！请按照菜单点菜！"
        continue
    fi

    case $Num in
        1)
            clear
            echo "你点了一份夫妻肺片,价格48元！"
            echo "夫妻肺片 48 元" >>cai.txt
            ;;
        2)
            clear
            echo "你点了一份五香牛肉,价格68元！"
            echo "五香牛肉 68 元" >>cai.txt
            ;;
        3)
            clear
            echo "你点了一份蒜泥黄瓜,价格28元！"
            echo "蒜泥黄瓜 28 元" >>cai.txt
            ;;
        4)
            clear
            echo "你点了一份糖醋鲤鱼,价格78元！"
            echo "糖醋鲤鱼 78 元" >>cai.txt
            ;;
        5)
            clear
            echo "你点了一份红烧排骨,价格98元！"
            echo "红烧排骨 98 元" >>cai.txt
            ;;
        6)
            clear
            echo "你点了一份红烧猪蹄,价格88元！"
            echo "红烧猪蹄 88 元" >>cai.txt
            ;;
        7)
            clear
            echo "你点了一份海鲜大咖,价格298元！"
            echo "海鲜大咖 298 元" >>cai.txt
            ;;
        8)
            clear
            echo "你点了一份澳洲龙虾,价格998元！"
            echo "澳洲龙虾 998 元" >>cai.txt
            ;;
        9)
            echo "你结束了点菜！你的菜品详细如下："
            awk '{print $1}' cai.txt |sort | uniq -c | sort -rn | awk '{print "你点了"$2"！""点了"$1"份！"}'
            echo "你本次消费金额如下："
            awk '{print $2}' cai.txt |xargs | tr ' ' '+' | bc | awk '{print "总价格为："$1"元！"}'
            echo "本酒店实行先买单后吃饭规则！"
            exit
    esac
done
