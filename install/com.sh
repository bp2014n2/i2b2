#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. $DIR/../env.properties

apt-get -y install openjdk-7-jdk unzip curl
cd ~
curl -s -o ~/jboss.zip http://54.93.194.56/jboss.zip
mkdir $JBOSS_HOME
unzip -d $JBOSS_HOME jboss.zip
rm -rf ~/jboss.zip