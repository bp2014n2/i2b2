i2b2$ont$db['host'] <- 'localhost'
i2b2$ont$db['port'] <- '5432'
i2b2$ont$db['username'] <- 'i2b2metadata'
i2b2$ont$db['password'] <- 'demouser'
i2b2$ont$db['name'] <- 'i2b2'
i2b2$ont$db['class'] <- 'org.postgresql.Driver'
i2b2$ont$db['jar'] <- paste(getwd(), '/postgresql-9.2-1002.jdbc4.jar', sep="/")
i2b2$ont$db['type'] <- 'postgresql'