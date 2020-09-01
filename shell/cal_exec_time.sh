#!/bin/bash

# Method 1: Precise to the second
start=$(date +%s)
# ...
# The program to be run
# ...
end=$(date +%s)
diff_time=$(( end - start ))
echo "spend time is $diff_time"


# Method 2: More precise timing
start=`date -d "now" +%s`
# ...
# The program to be run
# ...
end=`date -d "now" +%s`
diff_time=`echo "scale=2;$end-$start"|bc`
echo "spend time is $diff_time"

