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
sudo apt-get -y install ant >> $LOG_FILE
sudo apt-get -y install curl >> $LOG_FILE
sudo apt-get -y install openjdk-7-jdk >> $LOG_FILE
sudo apt-get -y install screen >> $LOG_FILE
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -  >> $LOG_FILE
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list' >> $LOG_FILE
sudo apt-get update >> $LOG_FILE
sudo apt-get -y install jenkins >> $LOG_FILE
sudo apt-get -y install unzip >> $LOG_FILE

echo "setting up webserver"
curl -s -o ~/i2b2webclient-1703a.zip https://dl.dropboxusercontent.com/u/23263423/i2b2webclient-1703a.zip >> $LOG_FILE
unzip i2b2webclient-1703a.zip >> $LOG_FILE
sudo cp -r ~/webclient /var/www/html/ >> $LOG_FILE
sudo cp -r $I2B2_HOME/admin /var/www/html/ >> $LOG_FILE

echo "downloading jboss"
curl -s -o ~/jboss-as-7.1.1.Final.zip https://dl.dropboxusercontent.com/u/23263423/jboss-as-7.1.1.Final.zip >> $LOG_FILE
unzip -d $JBOSS_HOME jboss-as-7.1.1.Final.zip >> $LOG_FILE

echo "configuring cells"
cd $I2B2_HOME >> $LOG_FILE
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i >> $LOG_FILE
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i >> $LOG_FILE

echo "building cells"
cd $I2B2_HOME >> $LOG_FILE
cd edu.harvard.i2b2.server-common >> $LOG_FILE
sudo ant clean dist deploy jboss_pre_deployment_setup >> $LOG_FILE
cd ../edu.harvard.i2b2.pm >> $LOG_FILE
sudo ant -f master_build.xml clean build-all deploy >> $LOG_FILE
cd ../edu.harvard.i2b2.ontology/ >> $LOG_FILE
sudo ant -f master_build.xml clean build-all deploy >> $LOG_FILE
cd ../edu.harvard.i2b2.crc/ >> $LOG_FILE
sudo ant -f master_build.xml clean build-all deploy >> $LOG_FILE

echo "cleaning up"
sudo rm -rf ~/jboss-as-7.1.1.Final.zip
sudo rm -rf ~/webclient
sudo rm -rf ~/i2b2webclient-1703a.zip

echo "starting jboss"
#sudo screen -dmS "I2B2" sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0
sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0

#clear
#echo "Success! Setup finished!";




