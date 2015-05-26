#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. $DIR/../env.properties

apt-get -y install openjdk-7-jdk unzip curl
curl -s -o jboss.zip http://54.93.194.56/jboss.zip
mkdir -p $JBOSS_HOME
unzip -d $JBOSS_HOME jboss.zip
rm -rf jboss.zip
cp ./jboss.service /etc/init.d/jboss
chmod 755 /etc/init.d/jboss
update-rc.d jboss defaults
service jboss start