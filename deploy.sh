#!/bin/bash

result=0
cd edu.harvard.i2b2.server-common/
ant deploy jboss_pre_deployment_setup
result=$((result + $?))
cd ../edu.harvard.i2b2.pm/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.ontology/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.crc/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.workplace/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.fr/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../edu.harvard.i2b2.im/
ant -f master_build.xml deploy
result=$((result + $?))
cd ../de.hpi.i2b2.girix
ant jboss_deploy
result=$((result + $?))
cd ..
exit $result
