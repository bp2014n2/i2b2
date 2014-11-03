#!/bin/bash

result=0
cd edu.harvard.i2b2.pm
sudo ant -f master_build.xml test
result=$((result + $?))
cd ../edu.harvard.i2b2.ontology
sudo ant -f master_build.xml test
result=$((result + $?))
cd ../edu.harvard.i2b2.crc
sudo ant -f master_build.xml test
result=$((result + $?))
cd ..
exit $result