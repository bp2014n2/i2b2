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
export WWW_HOME=/var/www/html/
mkdir $JBOSS_HOME
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
    echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | \
      sudo apt-key add -
    sudo apt-get update
    sudo apt-get -y install apache2 libapache2-mod-php5 php5-curl openjdk-7-jdk ant curl unzip r-base postgresql-server-dev-9.4
    sudo /etc/init.d/apache2 restart
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
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/csv
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/plots
    mkdir $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/RImage
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/csv
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/plots
    sudo chmod -R +w $I2B2_HOME/webclient/js-i2b2/cells/plugins/reportPlugin/assets/RImage
    sudo cp -r $I2B2_HOME/admin $WWW_HOME
    sudo cp -r $I2B2_HOME/webclient $WWW_HOME
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Downloading jboss"
progress &
progPid=$!
{
    cd ~
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
    sed "s|\${env\.I2B2_HOME}|`echo $I2B2_HOME`|g" */build.properties -i
    sed "s|\${env\.WWW_HOME}|`echo $WWW_HOME`|g" */build.properties -i
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i
    sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Building cells"
progress &
progPid=$!
{
    cd $I2B2_HOME
    sh build.sh
    sh deploy.sh
} >> $LOG_FILE
echo "" ; kill -13 "$progPid";

echo "Cleaning up"
rm -rf ~/jboss.zip

clear;
echo "Setup completed"
echo "start jboss with the following command"
echo "sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0"

