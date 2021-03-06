options( java.parameters = "-Xmx2g" )
require(RJDBC)

i2b2 <- list()
db <- list()

source("utils.r")
source("style.r")
source("i2b2.crc.r")
source("i2b2.ont.r")

executeQuery <- function(config=list(), query, ..., silent=T) {

  final_query <- sprintf(strunwrap(query), ...)
  if(!silent) {
    print(final_query)
  }
  con <- initializeConnection(config)
  result <- dbGetQuery(con, final_query)
  dbDisconnect(con)
  return(result)
  
}

initializeConnection <- function(config=list()) {
  drv <- JDBC(config['class'], config['jar'])
  return(dbConnect(drv, getConnectionString(config), config['username'], config['password']))
}
