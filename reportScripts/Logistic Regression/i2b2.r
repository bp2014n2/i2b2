require(RPostgreSQL)

executeQuery <- function(con, query, ...) {
  
  return(dbGetQuery(con, sprintf(query, ...)))
  
}

initializeCRCConnection <- function() {
  drv <- dbDriver("PostgreSQL")
  return(dbConnect(drv, dbname="i2b2", host="localhost", user="i2b2demodata", password="demouser", port="5432"))
}

destroyCRCConnection <- function(con) {
  
  dbDisconnect(con)
  
}