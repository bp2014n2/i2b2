#!/bin/bash

apt-get -y install openjdk-7-jdk r-base libproj-dev libgdal-dev
R CMD ./install_girix_packages.r
cp ./rserve.service /etc/init.d/rserve
update-rc.d rserve defaults
service rserve start
mkdir $GIRIX_ASSETS