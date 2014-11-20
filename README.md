##Repository of the BP2014N2 Bachelorprojekt

##Utilities

####Remove changes in config files from working copy:
~~~
git update-index --assume-unchanged edu.harvard.i2b2.crc/etc/jboss/crc-ds.xml;
git update-index --assume-unchanged edu.harvard.i2b2.crc/etc/spring/CRCLoaderApplicationContext.xml;
git update-index --assume-unchanged edu.harvard.i2b2.crc/etc/spring/crc_application_directory.properties;
git update-index --assume-unchanged edu.harvard.i2b2.fr/etc/spring/fr_application_directory.properties;
git update-index --assume-unchanged edu.harvard.i2b2.im/etc/jboss/im-ds.xml;
git update-index --assume-unchanged edu.harvard.i2b2.im/etc/spring/im_application_directory.properties;
git update-index --assume-unchanged edu.harvard.i2b2.ontology/etc/jboss/ont-ds.xml;
git update-index --assume-unchanged edu.harvard.i2b2.ontology/etc/spring/ontology_application_directory.properties;
git update-index --assume-unchanged edu.harvard.i2b2.workplace/etc/jboss/work-ds.xml;
git update-index --assume-unchanged edu.harvard.i2b2.workplace/etc/spring/workplace_application_directory.properties;
~~~