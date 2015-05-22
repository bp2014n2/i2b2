#!/bin/bash

apt-get -y install apache2 libapache2-mod-php5 php5-curl curl
/etc/init.d/apache2 restart