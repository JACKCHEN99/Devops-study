#!/bin/bash
cpu_rem=`vmstat | awk 'NR>2{print $(NF-2)}'`
mem_rem=`free -h | awk 'NR==2{print $NF}'`
swap=`free -h | awk 'NR==3{print $2" "$3}'`
disk_used=`df -h | awk '/\/$/{print $(NF-1)}'`

echo "cpu free: $cpu_rem"
echo "free remain: $mem_rem"
echo "disk used: $disk_used"
