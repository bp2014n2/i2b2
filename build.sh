cd edu.harvard.i2b2.server-common
sudo ant clean dist
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml clean build-all
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml clean build-all
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml clean build-all