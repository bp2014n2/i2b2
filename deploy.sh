cd edu.harvard.i2b2.server-common
sudo ant deploy jboss_pre_deployment_setup
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml deploy
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml deploy
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml deploy