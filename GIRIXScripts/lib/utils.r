strunwrap <- function(str) {
  return(strwrap(str, width=10000, simplify=TRUE))
}

escape <- function(string) {
  return(gsub("[\\]", "\\\\\\\\", string))
}

getConceptName <- function(concept.cd) {
  name <- i2b2$ont$getConceptNameForBasecode(concept.cd)[1,]
  return(ifelse(is.na(name), concept.cd, name))
}

i2b2DateToPOSIXlt <- function(strdate) {
  return(as.POSIXlt(strdate, format='%m/%d/%Y'))
}

POSIXltToi2b2Date <- function(date) {
  return(strftime(date, format="%d/%m/%Y"))
}

posixltToPSQLDate <- function(date) {
  return(strftime(date, format="%Y-%m-%dT%H:%M:%S"))
}

getConnectionString <- function(config=list()) {
  return(paste('jdbc:', config['type'], '://', config['host'], ':', config['port'], '/', config['name'], sep=''))
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

sort.data.frame <- function(data_frame, column, decreasing=FALSE) {
  data_frame.sorted <- data_frame[order(data_frame[,column], decreasing=decreasing),]
  rownames(data_frame.sorted) <- NULL
  return(data_frame.sorted)
}

printPatientSet <- function(id) {
  return(ifelse(id < 0, 'all Patients', i2b2$crc$getPatientSetDescription(id)))
}

smoothedLine <- function(x, y) {
  xnna <- x[!is.na(y)]
  ynna <- y[!is.na(y)]
  lines(smooth.spline(xnna, ynna, spar=0.5, tol=0.01), lwd=2)
}

getDate <- function(year, quarter) {
  month <- strtoi(quarter) * 3 - 2
  if (month < 10) {
    filler <- '0'
  } else {
    filler <- ''
  }
  date <- paste0(year,'-',filler,month,'-01')
  return(date)
}

utils.random_dates <- function(N, st="2011/01/01", et="2014/12/31") {
    st <- as.POSIXct(as.Date(st))
    et <- as.POSIXct(as.Date(et))
    dt <- as.numeric(difftime(et,st,unit="sec"))
    ev <- sort(runif(N, 0, dt))
    rt <- st + ev
    return(rt)
}

utils.random_mortality <- function(patient_set){
  death_dates <- random_dates(nrow(patient_set))
  patient_set$death_date <- death_dates
  return(patient_set)
}

utils.roundUp <- function(x) 10^ceiling(log10(x))
