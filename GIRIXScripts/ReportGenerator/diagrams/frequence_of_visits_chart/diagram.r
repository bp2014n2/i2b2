# ---- code ----
setwd("../../../")

frequence_of_visits <- function(patientsWithObservation, patientsWithoutObservation) {
 
  par(mai=c(1,1,0.5,0.5),omi=c(0.65,0.25,0.75,0.75),family="Lato Light",las=1)
  
  # Daten einlesen und Grafik vorbereiten
  farbe1_150<-rgb(68,90,111,150,maxColorValue=255) 
  farbe1_50<-rgb(68,90,111,50,maxColorValue=255)   
  farbe2_150<-rgb(255,97,0,150,maxColorValue=255)  
  farbe2_50<-rgb(255,97,0,50,maxColorValue=255)    
  
  # Grafik definieren und weitere Elemente

  if(is.null(params$icd)) {
    p.with.count <- i2b2$crc$getPatientsCountWithObservation()
    p.without.count <- i2b2$crc$getPatientsCountWithoutObservation()
  } else {
    p.with.count <- i2b2$crc$getPatientsCountWithObservation(concept=params$icd)
    p.without.count <- i2b2$crc$getPatientsCountWithoutObservation(concept=params$icd)
  }
  print(p.with.count)
  print(p.without.count)

  p.with.date <- strptime(unlist(patientsWithObservation[1], use.names=F), "%Y-%m-%d %H:%M:%S")
  p.with.data <- unlist(lapply(as.numeric(unlist(c(patientsWithObservation[2]))), FUN = function(r) {r/p.with.count}))
  print(patientsWithObservation)
  mo <- quarters(p.with.date)
  yr <- strftime(p.with.date, "%Y")
  dd <- data.frame(mo, yr, p.with.data)

  p.with.agg <- aggregate(p.with.data ~ mo + yr, dd, FUN = sum)
  p.with.agg$date <- as.POSIXct(paste(p.with.agg$yr, as.numeric(substr(p.with.agg$mo,2,2))*3, "01", sep = "-"))

  p.without.date <- strptime(unlist(patientsWithoutObservation[1], use.names=F), "%Y-%m-%d %H:%M:%S")
  p.without.data <- unlist(lapply(as.numeric(unlist(c(patientsWithoutObservation[2]))), FUN = function(r) {r/p.without.count}))

  mo <- quarters(p.without.date)
  yr <- strftime(p.without.date, "%Y")
  dd <- data.frame(mo, yr, p.without.data)

  p.without.agg <- aggregate(p.without.data ~ mo + yr, dd, FUN = sum)
  p.without.agg$date <- as.POSIXct(paste(p.without.agg$yr, as.numeric(substr(p.without.agg$mo,2,2))*3, "01", sep = "-"))
  
  plot(p.with.agg$date,p.with.agg$p.with.data,type="n",xlab="",ylab="Relative Anzahl")

  # axis(2,col=par("bg"),col.ticks="grey81", lwd.ticks=0.5,tck=-0.025)
  lines(p.with.agg$date,p.with.agg$p.with.data,type="l",col=farbe1_150,lwd=3,xpd=T)
  lines(p.without.agg$date,p.without.agg$p.without.data,type="l",col=farbe2_150,lwd=3)
  text(head(p.with.agg$date, 1),max(p.without.agg$p.without.data, p.with.agg$p.with.data)*0.9,"Mit Knorpelkrankheiten",adj=0,cex=1,col=farbe1_150)
  text(head(p.with.agg$date, 1),max(p.without.agg$p.without.data, p.with.agg$p.with.data)*0.85,"Ohne Knorpelkrankheiten",adj=0,cex=1,col=farbe2_150)
  beginn<-c(head(p.with.agg$date, 1)); ende<-c(tail(p.with.agg$date, 1))
  farbe<-c(farbe1_50)
  for(i in 1:length(beginn)) {
    xx<-c(p.with.agg$date,rev(p.with.agg$date)); yy<-c(p.with.agg$p.with.data,rev(p.without.agg$p.without.data))
    polygon(xx,yy,col=farbe[i],border=F)
  }
  
  # Betitelung
  mtext("Frequenz der Arztbesuche",3,line=1.3,adj=0,family="Lato Black",cex=1.2,outer=T)
  if(!is.null(input.params$icd)) {
     mtext(paste0("Analysierte ICD: ", params$icd),3,line=0,adj=0,cex=0.9,outer=T)
  } else {
     mtext("\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\",3,line=0,adj=0,cex=0.9,outer=T)
  }
  mtext("Elsevier Health Analytics",1,line=3,adj=1,cex=0.65,font=3)
}  

frequence_of_visits_main <- function() {
  if(is.null(params$icd)) {
    patientsWithObservation <- i2b2$crc$getVisitCountForPatientsWithObservation()
    patientsWithoutObservation <- i2b2$crc$getVisitCountForPatientsWithoutObservation()
  } else {
    print(c(params$icd))
    patientsWithObservation <- i2b2$crc$getVisitCountForPatientsWithObservation(concepts=c(params$icd))
    patientsWithoutObservation <- i2b2$crc$getVisitCountForPatientsWithoutObservation(concepts=c(params$icd))
  }
  print(patientsWithObservation)
  frequence_of_visits(patientsWithObservation, patientsWithoutObservation)
}

frequence_of_visits_main()
