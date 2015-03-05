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

age <- function(from, to) {
  from_lt = as.POSIXlt(from)
  to_lt = as.POSIXlt(to)
  
  age = to_lt$year - from_lt$year
  
  ifelse(to_lt$mon < from_lt$mon |
           (to_lt$mon == from_lt$mon & to_lt$mday < from_lt$mday),
         age - 1, age)
}

countCharOccurrences <- function(char, s) {
  s2 <- gsub(char,"",s)
  return (nchar(s) - nchar(s2))
}