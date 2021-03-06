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
. ./env.properties
mkdir -p $HOME/log
export LOG_FILE=$HOME/log/log.txt

echo "installing dependencies"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh install.sh $*
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "building i2b2"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh build.sh $*
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "deploying i2b2"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh deploy.sh $*
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

clear;
echo "Setup completed"
cd $I2B2_HOME
sh info.sh $*

