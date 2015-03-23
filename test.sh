#!/bin/bash

cd edu.harvard.i2b2.pm
ant -f master_build.xml test
cd ../edu.harvard.i2b2.ontology
ant -f master_build.xml test
cd ../edu.harvard.i2b2.crc
ant -f master_build.xml test
cd ../edu.harvard.i2b2.workplace
ant -f master_build.xml test
cd ../edu.harvard.i2b2.fr
ant -f master_build.xml test
cd ../edu.harvard.i2b2.im
ant -f master_build.xml test
exit 0
