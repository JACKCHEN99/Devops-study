#!/bin/bash
# func: Guess real age
age=18
while true;do
    read -p "Please input a age >> " input_age
    [[ ! $input_age =~ ^[0-9]+$ ]] && echo "Input para must be positive int!" && exit

    if [ $input_age -gt $age ];then
        echo -e "Your guess is biger than age \n"
    elif [ $input_age -lt $age ];then
        echo -e "Your guess is less than age \n"
    else
        echo "Congratutions!"
        exit
    fi
done