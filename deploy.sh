#!/bin/bash

export JBOSS_HOME=$1

result=0
echo "deploy before server-common"
cd edu.harvard.i2b2.server-common
sudo ant deploy jboss_pre_deployment_setup
result=$((result + $?))
echo "deploy before pm cell"
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml deploy
result=$((result + $?))
echo "deploy before ontology"
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml deploy
result=$((result + $?))
echo "deploy before crc"
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml deploy
result=$((result + $?))
cd ..
exit $result