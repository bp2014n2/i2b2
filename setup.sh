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
export I2B2_HOME=`pwd`
cd ~
export ANT_HOME=/usr/share/ant
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JBOSS_HOME=`pwd`/jboss
mkdir $JBOSS_HOME
mkdir log
export LOG_FILE=`pwd`/log/log.txt
touch $LOG_FILE

echo "Installing software"
progress &
progPid=$!
{
    sudo apt-get -y install apache2 >> $LOG_FILE
    sudo apt-get -y install libapache2-mod-php5 >> $LOG_FILE
    sudo apt-get -y install php5-curl >> $LOG_FILE
    sudo /etc/init.d/apache2 restart >> $LOG_FILE
    sudo apt-get -y install openjdk-7-jdk >> $LOG_FILE
    sudo apt-get -y install ant >> $LOG_FILE
    sudo apt-get -y install curl >> $LOG_FILE
    sudo apt-get -y install screen >> $LOG_FILE
    sudo apt-get -y install unzip >> $LOG_FILE
}  >$LOG_FILE 2>&1
echo "" ; kill -13 "$progPid";

echo "Setting up webserver"
progress &
progPid=$!
{
    sudo cp -r $I2B2_HOME/admin /var/www/html/ >> $LOG_FILE
    sudo cp -r $I2B2_HOME/webclient /var/www/html/ >> $LOG_FILE
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Downloading jboss"
progress &
progPid=$!
{
    curl -s -o ~/jboss.zip http://54.93.194.56/jboss.zip >> $LOG_FILE
    unzip -d $JBOSS_HOME jboss.zip >> $LOG_FILE
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Configuring cells"
progress &
progPid=$!
{
    cd $I2B2_HOME >> $LOG_FILE
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i >> $LOG_FILE
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i >> $LOG_FILE
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Building cells"
progress &
progPid=$!
{
    sudo sh $I2B2_HOME/build.sh >> $LOG_FILE
    sudo sh $I2B2_HOME/deploy.sh >> $LOG_FILE
} >$LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Cleaning up"
sudo rm -rf ~/jboss.zip

clear;
echo "Setup completed"
echo "start jboss with the following command"
echo "sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0"

