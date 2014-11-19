sed "s|54\.93\.194\.65:5432|`echo localhost:5432`|g" */etc/jboss/*-ds.xml -i
sed "s|54\.93\.194\.65:5432|`echo localhost:5432`|g" */etc/spring/*LoaderApplicationContext.xml -i