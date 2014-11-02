echo "configuring cells"
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i

echo "building cells"
cd edu.harvard.i2b2.server-common
sudo ant clean dist deploy jboss_pre_deployment_setup
cd ../edu.harvard.i2b2.pm
sudo ant -f master_build.xml clean build-all deploy
cd ../edu.harvard.i2b2.ontology/
sudo ant -f master_build.xml clean build-all deploy
cd ../edu.harvard.i2b2.crc/
sudo ant -f master_build.xml clean build-all deploy