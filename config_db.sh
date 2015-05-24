#!/bin/bash

. env.properties

sed "s|54\.93\.194\.65:5432|`echo $DB_LOC`|g" */etc/jboss/*-ds.xml -i
sed "s|54\.93\.194\.65:5432|`echo $DB_LOC`|g" */etc/spring/*LoaderApplicationContext.xml -i
