i2b2$crc$db['host'] <- 'localhost'
i2b2$crc$db['port'] <- '5432'
i2b2$crc$db['username'] <- 'i2b2demodata'  #add HPCC username here (& execute "git update-index --assume-unchanged ./GIRIXScripts/lib/i2b2.crc.config_hpcc.r")
i2b2$crc$db['password'] <- 'demouser'  #add HPCC password here
i2b2$crc$db['name'] <- 'i2b2'
i2b2$crc$db['class'] <- 'org.postgresql.Driver'
i2b2$crc$db['jar'] <- paste(getwd(), 'postgresql-9.2-1002.jdbc4.jar', sep="/")
i2b2$crc$db['type'] <- 'postgresql'
