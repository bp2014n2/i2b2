Utils.strunwrap <- function(str) {
  return(strwrap(str, width=10000, simplify=TRUE))
}

Utils.escape <- function(string) {
  return(gsub("[\\]", "\\\\\\\\", string))
}

Utils.getConceptName <- function(concept.cd) {
  name <- i2b2$ont$getConceptNameForBasecode(concept.cd)[1,]
  return(ifelse(is.na(name), concept.cd, name))
}

Utils.i2b2DateToPOSIXlt <- function(strdate) {
  return(as.POSIXlt(strdate, format='%m/%d/%Y'))
}

Utils.POSIXltToi2b2Date <- function(date) {
  return(strftime(date, format="%d/%m/%Y"))
}

Utils.posixltToPSQLDate <- function(date) {
  return(strftime(date, format="%Y-%m-%dT%H:%M:%S"))
}

Utils.getConnectionString <- function(config=list()) {
  return(paste('jdbc:', config['type'], '://', config['host'], ':', config['port'], '/', config['name'], sep=''))
}

Utils.age <- function(from, to) {
  from_lt = as.POSIXlt(from)
  to_lt = as.POSIXlt(to)
  
  age = to_lt$year - from_lt$year
  
  ifelse(to_lt$mon < from_lt$mon |
           (to_lt$mon == from_lt$mon & to_lt$mday < from_lt$mday),
         age - 1, age)
}

Utils.countCharOccurrences <- function(char, s) {
  s2 <- gsub(char,"",s)
  return (nchar(s) - nchar(s2))
}

Utils.sort.data.frame <- function(data_frame, column) {
  data_frame.sorted <- data_frame[order(-data_frame[,column]),]
  rownames(data_frame.sorted) <- NULL
  return(data_frame.sorted)
}

Utils.printPatientSet <- function(id) {
  return(ifelse(id < 0, 'all Patients', i2b2$crc$getPatientSetDescription(id)))
}

Utils.smoothedLine <- function(x, y) {
  xnna <- x[!is.na(y)]
  ynna <- y[!is.na(y)]
  lines(smooth.spline(xnna, ynna, spar=0.5, tol=0.01), col="red", lwd=2)
}