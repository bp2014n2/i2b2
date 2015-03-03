strunwrap <- function(str) {
  return(strwrap(str, width=10000, simplify=TRUE))
}

i2b2DateToPOSIXlt <- function(strdate) {
  return(as.POSIXlt(strdate, format='%m/%d/%Y'))
}

POSIXltToi2b2Date <- function(date) {
  return(strftime(date, format="%d/%m/%Y"))
}

posixltToPSQLDate <- function(date) {
  return(strftime(date, format="%Y-%m-%d"))
}