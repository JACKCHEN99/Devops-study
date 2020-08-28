#!/usr/bin/env bash
# func: 1+2+3+...9

# while
i=0
while [ $i -lt 10 ]; do
    echo $i
    let i++
    # ((i+=1))  # same as up
done

# for
for (( i = 0; i < 10; i++ )); do
# for i in {0..9}; do    # same as up
    echo $i
done

# until
i=0
until [ $i -gt 9 ];do
    echo $i
    let i++
done

