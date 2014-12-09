#!/bin/bash

export JBOSS_HOME=$1

result=0
echo "build before server-common"
cd edu.harvard.i2b2.server-common
sudo ant clean dist
result=$((result + $?))
echo "build before pm cell"
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml clean build-all
result=$((result + $?))
echo "build before ontology"
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml clean build-all
result=$((result + $?))
echo "build before crc"
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml clean build-all
result=$((result + $?))
cd ..
exit $result