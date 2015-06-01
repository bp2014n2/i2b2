#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

. $DIR/env.properties

/usr/lib/R/bin/R CMD $RSERVE_HOME/libs/Rserve --no-save --RS-port 6311
