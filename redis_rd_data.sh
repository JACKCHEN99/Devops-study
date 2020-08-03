#!/bin/bash
#**************************************************************************
# Author:       Mrchen
# Scripts_Name: redis_rddata.sh
# Description:  批量插入 n 条数据到redis, 数据格式:{K1 V1} - {Kn Vn}
#**************************************************************************

# 生成随机数
read -p "redis插入的数据量: " num
echo "正在插入 $num 条数据,顺序: 1.生成数据 -> 2.转换数据 -> 3.插入数据. 请耐心等待..."
i=1
[ -f 2.rd ] && rm -f 2.rd
while [ $i -le $num ];do
	echo "set k$i $i" >> 2.rd;let i++
done
echo "1.生成数据 成功"

# 把2.rd的数据, 转换成redis --pipe支持的格式, 并保存到1.rd
while read CMD; do
	XS=($CMD); printf "*${#XS[@]}\r\n" >> 1.rd
	for X in $CMD; do printf "\$${#X}\r\n$X\r\n" >> 1.rd; done
done < 2.rd
echo "2.转换数据 成功"

# 导入生成的数据至redis
cat 1.rd | redis-cli -a 123 -p 6380 --pipe
# 清除临时文件
rm -rf 1.rd 2.rd