#! /usr/bin/Rscript

require(RSclient)
rsc <- RSconnect()
RSshutdown(rsc)
RSclose(rsc)