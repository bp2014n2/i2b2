#!/bin/bash

. ./env.properties

sed "s|10\.0\.0\.15:5432|`echo $DB_LOC`|g" */etc/jboss/*-ds.xml -i
sed "s|10\.0\.0\.15:5432|`echo $DB_LOC`|g" */etc/spring/*LoaderApplicationContext.xml -i

git update-index --assume-unchanged */etc/jboss/*-ds.xml;
