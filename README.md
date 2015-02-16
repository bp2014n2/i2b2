#Repository of the BP2014N2 Bachelorprojekt

## Setup

### local installation
`sudo apt-get -y install git; cd ~; git clone https://github.com/bp2014n2/i2b2.git; cd i2b2; sudo ./setup.sh`
### server installation
`sudo apt-get -y install git; cd ~; git clone https://github.com/bp2014n2/i2b2.git; cd i2b2; sudo ./setup.sh 54.93.194.65:5432`
### Report Cell installation
`sudo apt-get -y install git; cd ~; git clone https://github.com/bp2014n2/i2b2.git; cd i2b2; git checkout report; sudo ./setup.sh`

##Utilities

####Remove changes in config files from working copy:
~~~
git update-index --assume-unchanged */etc/spring/*LoaderApplicationContext.xml;
git update-index --assume-unchanged */etc/jboss/*-ds.xml;
git update-index --assume-unchanged */build.properties;
git update-index --assume-unchanged */etc/spring/*_application_directory.properties;
~~~
