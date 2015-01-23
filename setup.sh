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
export GIRI_HOME=`pwd`/GIRIScripts
mkdir $JBOSS_HOME
mkdir $GIRI_HOME
mkdir log
export LOG_FILE=`pwd`/log/log.txt

db_loc="localhost:5432"

if [ $# -ge 1 ]
then
    db_loc=$1
fi

echo "Installing software"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sudo apt-get -y install apache2 libapache2-mod-php5 php5-curl openjdk-7-jdk ant curl unzip r-base
    sudo /etc/init.d/apache2 restart
    sudo chmod +x install_giri_packages.r
    sudo R CMD ./install_giri_packages.r
}  >> $LOG_FILE 2>&1
echo "" ; kill -13 "$progPid";

echo "Setting up webserver"
progress &
progPid=$!
{
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/csv
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/plots
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/RImage
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/csv
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/plots
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/GIRIPlugin/assets/RImage
    sudo cp -r $I2B2_HOME/admin /var/www/html/
    sudo cp -r $I2B2_HOME/webclient /var/www/html/
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Downloading jboss"
progress &
progPid=$!
{
    curl -s -o ~/jboss.zip http://54.93.194.56/jboss.zip
    unzip -d $JBOSS_HOME jboss.zip
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Configuring cells"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh config_db.sh $db_loc
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Building cells"
progress &
progPid=$!
{
    sh $I2B2_HOME/build.sh
    sh $I2B2_HOME/deploy.sh
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Cleaning up"
rm -rf ~/jboss.zip

clear;
echo "Setup completed"
echo "start jboss with the following command"
echo "sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0"

