#!/bin/sh
echo $(echo "`echo '\\\\timing \\\\\\\\ \\\\i' $1 | sudo -u postgres psql i2b2 2> /dev/null`" | grep 'Time: [0-9,.]* ms' | sed -e 's/Time: //g' | sed -e 's/ ms/ + /g' | tr -d '\n' | sed -e 's/+ $//g' | sed -e 's/,/\./g') | bc
