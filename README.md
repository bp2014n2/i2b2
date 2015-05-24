#Repository of the BP2014N2 Bachelorprojekt

## Setup

### Installation
`sudo apt-get -y install git; cd ~; git clone https://github.com/bp2014n2/i2b2.git; cd i2b2; sudo ./setup.sh`

#### Options

- core: i2b2 Core-Cells
- girix: GIRIX-Cell
- app: all available cells
- web: Web-Client

#### Configuration

Configuration in `env.properties`

- I2B2_HOME: location of i2b2 source
- ANT_HOME: ant location
- JAVA_HOME: java location
- JBOSS_HOME: jboss install directory
- GIRIX_ASSETS: where girix assets are stored temporarily
- WWW_HOME: web server root
- WWW_LOC: upload location for girix assets
- DB_LOC: database location

##Utilities

####Remove changes in config files from working copy:
~~~
git update-index --assume-unchanged */etc/spring/*LoaderApplicationContext.xml;
git update-index --assume-unchanged */etc/jboss/*-ds.xml;
git update-index --assume-unchanged */build.properties;
git update-index --assume-unchanged */etc/spring/*_application_directory.properties;
~~~
