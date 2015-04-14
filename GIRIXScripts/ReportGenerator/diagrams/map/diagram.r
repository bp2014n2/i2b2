# ---- code ----
library(maptools)
library(rgdal)
library(RColorBrewer)

map <- function(){
  par(mar=c(0,0,0,0),oma=c(1,1,1,0), mfcol=c(1,1),family="Lato",las=1)
  # Daten einlesen und Grafik vorbereiten
  map_data<-readShapeSpatial("/home/ubuntu/i2b2/GIRIXScripts/ReportGenerator/diagrams/map/post_pl.shp",IDvar="PLZ99", proj4string=CRS("+proj=longlat"))
  map_data<-spTransform(map_data,CRS=CRS("+proj=merc"))
 farbe<-sample(1:7,length(map_data),replace=T)

  patient_data <- i2b2$crc$getPatientsWithPlz()
  patient_data$zip <- substring(patient_data$statecityzip_path, nchar(patient_data$statecityzip_path)-2, nchar(patient_data$statecityzip_path)-1) 
  zip_data <- aggregate(x=patient_data$count, by=list(patient_data$zip), FUN=sum)

  zip_data$zip <- as.numeric(zip_data[,1])
  map_data$zip <- as.numeric(substr(map_data$PLZ99, 1, 2))

  map_data <- merge(x=map_data, y=zip_data, by="zip") 

  color_nr <- cut(map_data$x, c(0,100,500,1000,5000,100000))
  colors<-brewer.pal(6, "Oranges")

  if(!is.null(params$plzFilter)) {
    map_data<-subset(map_data,substr(map_data$PLZ99,1,nchar(params$plzFilter))==params$plzFilter)
  }

  # Grafik erstellen und weitere Elemente
  plot(map_data,col=colors[color_nr],border=F)

  # Betitelung
  mtext("PLZ Grenzen",side=3,line=-4,adj=0,cex=1.7)
}
map()
