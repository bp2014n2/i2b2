#!/bin/bash

cd edu.harvard.i2b2.pm
sudo ant -f master_build.xml test
cd ../edu.harvard.i2b2.ontology
sudo ant -f master_build.xml test
cd ../edu.harvard.i2b2.crc
sudo ant -f master_build.xml test
exit 0