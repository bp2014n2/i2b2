strunwrap <- function(str) {
  return(strwrap(str, width=10000, simplify=TRUE))
}

i2b2DateToPOSIXlt <- function(strdate) {
  return(as.POSIXlt(strdate, format='%m/%d/%Y'))
}

posixltToPSQLDate <- function(date) {
  return(strftime(date, format="%Y-%m-%d"))
}