i2b2$crc$db['host'] <- '54.93.130.121'
i2b2$crc$db['port'] <- '8010'
i2b2$crc$db['username'] <- ''  #add HPCC username here (& execute "git update-index --assume-unchanged ./GIRIXScripts/lib/i2b2.crc.config_hpcc.r")
i2b2$crc$db['password'] <- ''  #add HPCC password here
i2b2$crc$db['name'] <- ''
i2b2$crc$db['class'] <- 'de.hpi.hpcc.main.HPCCDriver'
i2b2$crc$db['jar'] <- paste(getwd(), 'lib/jdbc-hpcc.jar', sep="/")
i2b2$crc$db['type'] <- 'hpcc'