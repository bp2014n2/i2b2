#!/bin/bash

progress() {
  pc=0;
  while true
    do
      echo -n -e "[$pc sec]\033[0K\r"
      sleep 1
      ((pc++))
    done
}

clear;
echo "######################"
echo "Running Setup"
echo "######################"


# setup environment
sh set_env.sh
. env.properties
mkdir $HOME/log
export LOG_FILE=$HOME/log/log.txt

echo $*
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh install.sh $*
    sh build.sh $*
    sh deploy.sh $*
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

clear;
echo "Setup completed"
echo "start jboss with the following command"
echo "sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0"

