#!/bin/bash
# func: Alarm if the disk root partition is more than 70% occupied
# desc: Can be improved to >90=>Critical >70=>Error >50=>Warning
disk_user=`df -h | awk '/\/$/{print $5}' | tr -d %`
[ $disk_user -gt 70 ] && echo -e "\033[41;37m echo "Warning: the disk is not enough! Used: ${disk_user}%. \033[0m"