# ---- code ----
library(xlsx)
setwd("../../../")

frequence_of_visits <- function() {
 
  par(mai=c(1,1,0.5,0.5),omi=c(0.65,0.25,0.75,0.75),family="Lato Light",las=1)
  
  # Daten einlesen und Grafik vorbereiten
  
  rs<-read.xlsx("ReportGenerator/diagrams/frequence_of_visits_chart/data.xls",1,header=F)
  farbe1_150<-rgb(68,90,111,150,maxColorValue=255) 
  farbe1_50<-rgb(68,90,111,50,maxColorValue=255)   
  farbe2_150<-rgb(255,97,0,150,maxColorValue=255)  
  farbe2_50<-rgb(255,97,0,50,maxColorValue=255)    
  attach(rs)
  
  # Grafik definieren und weitere Elemente
  
  plot(X1,X11,axes=F,type="n",xlab="",ylab="Anzahl (je 100 Tsd. Einwohner)",
          cex.lab=1,xlim=c(1820,2020),ylim=c(10,40),xpd=T)
  axis(1,at=c(1820,1870,1920,1970,2010))
  axis(2,at=c(10,15,20,25,30,35,40),col=par("bg"),col.ticks="grey81",
          lwd.ticks=0.5,tck=-0.025)
  lines(X1,X11,type="l",col=farbe1_150,lwd=3,xpd=T)
  lines(X1,X12,type="l",col=farbe2_150,lwd=3)
  text(1910,35,"Mit \nRückenschmerzen",adj=0,cex=1,col=farbe1_150)
  text(1850,22,"Ohne \nRückenschmerzen",adj=0,cex=1,col=farbe2_150)
  beginn<-c(1817,1915,1919,1972); ende<-c(1914,1918,1971,2000)
  farbe<-c(farbe1_50,farbe2_50,farbe1_50,farbe2_50)
  for(i in 1:length(beginn)) {
    mysubset<-subset(rs,X1 >= beginn[i] & X1 <= ende[i])
    attach(mysubset)
    xx<-c(mysubset$X1,rev(mysubset$X1)); yy<-c(mysubset$X11,rev(mysubset$X12))
    polygon(xx,yy,col=farbe[i],border=F)
  }
  
  # Betitelung
  
  mtext("Frequenz der Besuche bei 'Orthopäde'",3,line=1.3,adj=0,family="Lato Black",cex=1.2,outer=T)
  mtext("Frequence for all patients",3,line=0,adj=0,cex=0.9,outer=T)
  mtext("Elsevier Health Analytics",1,line=3,adj=1,cex=0.65,font=3)
}  

frequence_of_visits_main <- function() {
  patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, 100)
  # if(!is.null(params$limit)){
  #   patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, params$limit)
  # } else {
  #   patients <- i2b2$crc$getPatients(model.patient_set)
  # } 
  frequence_of_visits()
}

frequence_of_visits_main()
