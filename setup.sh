#!/bin/sh

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

echo "installing software"
sudo apt-get -y install apache2 >> $LOG_FILE
sudo apt-get -y install libapache2-mod-php5 >> $LOG_FILE
sudo apt-get -y install php5-curl >> $LOG_FILE
sudo /etc/init.d/apache2 restart >> $LOG_FILE
sudo apt-get -y install openjdk-7-jdk >> $LOG_FILE
sudo apt-get -y install ant >> $LOG_FILE
sudo apt-get -y install curl >> $LOG_FILE
sudo apt-get -y install screen >> $LOG_FILE
sudo apt-get -y install unzip >> $LOG_FILE

echo "setting up webserver"
sudo cp -r $I2B2_HOME/admin /var/www/html/ >> $LOG_FILE
sudo cp -r $I2B2_HOME/webclient /var/www/html/ >> $LOG_FILE

echo "downloading jboss"
curl -s -o ~/jboss.zip http://54.93.194.56/jboss.zip >> $LOG_FILE
unzip -d $JBOSS_HOME jboss.zip >> $LOG_FILE

echo "configuring cells"
cd $I2B2_HOME >> $LOG_FILE
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i >> $LOG_FILE
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i >> $LOG_FILE

echo "building cells"
sudo sh $I2B2_HOME/build.sh >> $LOG_FILE
sudo sh $I2B2_HOME/deploy.sh >> $LOG_FILE

echo "cleaning up"
sudo rm -rf ~/jboss.zip

#echo "starting jboss"
#sudo screen -dmS "I2B2" sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0
#sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0

#clear
echo "setup finished"
echo "start jboss with the following command"
echo "sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0"