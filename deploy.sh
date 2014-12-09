#!/bin/bash

result=0
cd edu.harvard.i2b2.server-common
sudo ant deploy jboss_pre_deployment_setup
result=$((result + $?))
echo $JBOSS_HOME
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml deploy
result=$((result + $?))
cd ..
exit $result