#!/bin/sh

#Insert correct path here
export JBOSS_HOME=~/JBOSS


export I2B2_HOME=~/I2B2

# Download all files
sudo apt-get update
sudo apt-get -y install git
sudo apt-get -y install ant
sudo apt-get -y install unzip
sudo apt-get -y install openjdk-7-jdk
sudo apt-get -y install apache2 apache2-doc 
sudo apt-get -y install curl
sudo apt-get -y install screen
wget -q -O - https://jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'

# Link to i2b2webclient
# https://dl.dropboxusercontent.com/u/23263423/i2b2webclient-1703a.zip
mkdir ~/Downloads
curl -s -o ~/Downloads/i2b2webclient-1703a.zip https://dl.dropboxusercontent.com/u/23263423/i2b2webclient-1703a.zip
cd ~/Downloads
unzip i2b2webclient-1703a.zip

# Link to JBOSS
# https://dl.dropboxusercontent.com/u/23263423/jboss-as-7.1.1.Final.zip
curl -s -o ~/Downloads/jboss-as-7.1.1.Final.zip https://dl.dropboxusercontent.com/u/23263423/jboss-as-7.1.1.Final.zip
mkdir jboss-as-7.1.1.Final
mv jboss-as-7.1.1.Final.zip jboss-as-7.1.1.Final/
cd jboss-as-7.1.1.Final
unzip jboss-as-7.1.1.Final.zip

# load git repository
mkdir $I2B2_HOME
mkdir $JBOSS_HOME
cd $I2B2_HOME

export I2B2_HOME=$I2B2_HOME/eha-i2b2

# setup JBOSS directory
cp -r ~/Downloads/jboss-as-7.1.1.Final $JBOSS_HOME
export JBOSS_HOME=$JBOSS_HOME/jboss-as-7.1.1.Final

# copy webserver folders
sudo cp -r ~/Downloads/webclient /var/www/html/
sudo cp -r $I2B2_HOME/admin /var/www/html/

# configure ip and ports
cd $I2B2_HOME/edu.harvard.i2b2.ontology/etc/spring
head -n -1 `echo $I2B2_HOME`/edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties > temp.txt ; mv temp.txt `echo $I2B2_HOME`/edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties
echo "edu.harvard.i2b2.ontology.applicationdir=`echo $JBOSS_HOME`/standalone/configuration/ontologyapp" >> `echo $I2B2_HOME`/edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties

cd $I2B2_HOME/edu.harvard.i2b2.crc/etc/spring
head -n -1 `echo $I2B2_HOME`/edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties > temp.txt ; mv temp.txt `echo $I2B2_HOME`/edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties
echo "edu.harvard.i2b2.ontology.applicationdir=`echo $JBOSS_HOME`/standalone/configuration/crcapp" >> `echo $I2B2_HOME`/edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties

#Building all services
cd $I2B2_HOME
cd edu.harvard.i2b2.server-common
ant clean dist deploy jboss_pre_deployment_setup
#echo $JBOSS_HOME
cd ../edu.harvard.i2b2.pm
ant -f master_build.xml clean build-all deploy
#echo $JBOSS_HOME
cd ../edu.harvard.i2b2.ontology/
ant -f master_build.xml clean build-all deploy
#echo $JBOSS_HOME
cd ../edu.harvard.i2b2.crc/
ant -f master_build.xml clean build-all deploy


#starting JBOSS
sudo screen -dmS "I2B2" sudo sh `echo $JBOSS_HOME`/bin/standalone.sh -b 0.0.0.0

clear
echo "Success! Setup finished!";
