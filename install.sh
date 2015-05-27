#!/bin/bash

apt-get update
apt-get install -y ant
ant -f util/install.xml $*
