#!/bin/sh

# setup environment
export I2B2_HOME=`pwd`
cd ~
export ANT_HOME=/usr/share/ant
export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
export JBOSS_HOME=`pwd`/jboss
mkdir $JBOSS_HOME

# installing software
sudo apt-get -y install apache2
sudo apt-get -y install libapache2-mod-php5
sudo apt-get -y install git
sudo apt-get -y install ant
sudo apt-get -y install curl
sudo apt-get -y install openjdk-7-jdk
sudo apt-get -y install screen
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get -y install jenkins
sudo apt-get -y install unzip

# setting up webserver
curl -s -o ~/i2b2webclient-1703a.zip https://dl.dropboxusercontent.com/u/23263423/i2b2webclient-1703a.zip
unzip i2b2webclient-1703a.zip
sudo cp -r ~/webclient /var/www/html/
sudo cp -r $I2B2_HOME/admin /var/www/html/

# Download jboss
curl -s -o ~/jboss-as-7.1.1.Final.zip https://dl.dropboxusercontent.com/u/23263423/jboss-as-7.1.1.Final.zip
unzip -d $JBOSS_HOME jboss-as-7.1.1.Final.zip

# configuring cells
cd $I2B2_HOME
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i

# build cells
cd $I2B2_HOME
cd edu.harvard.i2b2.server-common
sudo ant clean dist deploy jboss_pre_deployment_setup
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml clean build-all deploy
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml clean build-all deploy
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml clean build-all deploy

# start jboss
sudo screen -dmS "I2B2" sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0
#sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0

#clear
#echo "Success! Setup finished!";




