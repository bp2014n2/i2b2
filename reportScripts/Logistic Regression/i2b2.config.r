db.host <- 'localhost'
db.port <- '5432'
db.username <- 'i2b2demodata'
db.password <- 'demouser'
db.name <- 'i2b2'
db.class <- 'org.postgresql.Driver'
db.jar <- 'postgresql-9.2-1002.jdbc4.jar'
db.type <- 'postgresql'
db.connection <- paste('jdbc:', db.type, '://', db.host, ':', db.port, '/', db.name, sep='')