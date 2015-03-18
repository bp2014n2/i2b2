#!/usr/local/bin/Rscript

stop <- function(){}
if(X11) {
  X11()
  stop <- function(){
    message("Press Return To Continue")
    invisible(readLines("stdin", n=1))
  }
}

random_dates <- function(N, st="2011/01/01", et="2014/12/31") {
    st <- as.POSIXct(as.Date(st))
    et <- as.POSIXct(as.Date(et))
    dt <- as.numeric(difftime(et,st,unit="sec"))
    ev <- sort(runif(N, 0, dt))
    rt <- st + ev
    return(rt)
}

random_mortality <- function(patient_set){
  death_dates <- random_dates(nrow(patient_set))
  patient_set$death_date <- death_dates
  return(patient_set)
}

roundUp <- function(x) 10^ceiling(log10(x))
