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

  p.with.date = strptime(unlist(patientsWithObservation[1], use.names=F), "%Y-%m-%d %H:%M:%S")
  p.with.data = as.numeric(unlist(c(patientsWithObservation[2])))

  mo <- quarters(p.with.date)
  yr <- strftime(p.with.date, "%Y")
  dd <- data.frame(mo, yr, p.with.data)

  p.with.agg <- aggregate(p.with.data ~ mo + yr, dd, FUN = sum)
  p.with.agg$date <- as.POSIXct(paste(p.with.agg$yr, as.numeric(substr(p.with.agg$mo,2,2))*3, "01", sep = "-"))
  


  p.without.date = strptime(unlist(patientsWithoutObservation[1], use.names=F), "%Y-%m-%d %H:%M:%S")
  p.without.data = as.numeric(unlist(c(patientsWithoutObservation[2])))

  mo <- quarters(p.without.date)
  yr <- strftime(p.without.date, "%Y")
  dd <- data.frame(mo, yr, p.without.data)

  p.without.agg <- aggregate(p.without.data ~ mo + yr, dd, FUN = sum)
  p.without.agg$date <- as.POSIXct(paste(p.without.agg$yr, as.numeric(substr(p.without.agg$mo,2,2))*3, "01", sep = "-"))
  
  plot(p.with.agg$date,p.with.agg$p.with.data,type="n",xlab="",ylab="Anzahl")

  # axis(2,col=par("bg"),col.ticks="grey81", lwd.ticks=0.5,tck=-0.025)
  lines(p.with.agg$date,p.with.agg$p.with.data,type="l",col=farbe1_150,lwd=3,xpd=T)
  lines(p.without.agg$date,p.without.agg$p.without.data,type="l",col=farbe2_150,lwd=3)
 #  text(1910,35,"Mit \nRückenschmerzen",adj=0,cex=1,col=farbe1_150)
 #  text(1850,22,"Ohne \nRückenschmerzen",adj=0,cex=1,col=farbe2_150)
 #  beginn<-c(1817,1915,1919,1972); ende<-c(1914,1918,1971,2000)
 #  farbe<-c(farbe1_50,farbe2_50,farbe1_50,farbe2_50)
 #  for(i in 1:length(beginn)) {
 #    mysubset<-subset(rs,X1 >= beginn[i] & X1 <= ende[i])
 #    attach(mysubset)
 #    xx<-c(mysubset$X1,rev(mysubset$X1)); yy<-c(mysubset$X11,rev(mysubset$X12))
 #    polygon(xx,yy,col=farbe[i],border=F)
 #  }
 #  
  # Betitelung
  
  mtext("Frequenz der Besuche bei 'Orthopäde'",3,line=1.3,adj=0,family="Lato Black",cex=1.2,outer=T)
  mtext("Frequence for all patients",3,line=0,adj=0,cex=0.9,outer=T)
  mtext("Elsevier Health Analytics",1,line=3,adj=1,cex=0.65,font=3)
}  

frequence_of_visits_main <- function() {
  patientsWithObservation <- i2b2$crc$getVisitCountForPatientsWithObservation()
  patientsWithoutObservation <- i2b2$crc$getVisitCountForPatientsWithoutObservation()
  # if(!is.null(params$limit)){
  #   patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, params$limit)
  # } else {
  #   patients <- i2b2$crc$getPatients(model.patient_set)
  # } 
  frequence_of_visits(patientsWithObservation, patientsWithoutObservation)
}

frequence_of_visits_main()
