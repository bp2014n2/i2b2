#!/bin/bash

. env.properties
sh config_db.sh $db_loc
sed "s|\${env\.I2B2_HOME}|`echo $I2B2_HOME`|g" */build.properties -i
sed "s|\${env\.WWW_LOC}|`echo $WWW_LOC`|g" */build.properties -i
sed "s|\${env\.GIRIX_ASSETS}|`echo $GIRIX_ASSETS`|g" */build.properties -i
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */build.properties -i
sed "s|\${env\.JBOSS_HOME}|`echo $JBOSS_HOME`|g" */etc/spring/*_application_directory.properties -i