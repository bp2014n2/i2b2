#!/bin/bash

result=0
cd edu.harvard.i2b2.server-common/
ant clean dist
result=$((result + $?))
cd edu.harvard.i2b2.common/
ant clean dist
result=$((result + $?))
cd ../edu.harvard.i2b2.pm/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../edu.harvard.i2b2.ontology/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../edu.harvard.i2b2.crc/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../edu.harvard.i2b2.workplace/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../edu.harvard.i2b2.fr/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../edu.harvard.i2b2.im/
ant -f master_build.xml clean build-all
result=$((result + $?))
cd ../de.erlangen.i2b2.giri
ant -f master_build.xml build-all
result=$((result + $?))
cd ..
exit $result