#!/bin/bash

db_loc="localhost:5432"

if [ $# -ge 1 ]
then
    db_loc=$1
fi

sed "s|54\.93\.194\.65:5432|`echo $db_loc`|g" */etc/jboss/*-ds.xml -i
sed "s|54\.93\.194\.65:5432|`echo $db_loc`|g" */etc/spring/*LoaderApplicationContext.xml -i
