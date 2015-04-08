# ---- code ----
library(maptools)
library(rgdal)
library(RColorBrewer)

map <- function(){
  par(mar=c(0,0,0,0),oma=c(1,1,1,0), mfcol=c(1,1),family="Lato",las=1)
  # Daten einlesen und Grafik vorbereiten
  y<-readShapeSpatial("/home/ubuntu/i2b2/GIRIXScripts/ReportGenerator/diagrams/map/post_pl.shp",proj4string=CRS("+proj=longlat"))
  x=spTransform(y,CRS=CRS("+proj=merc"))
  farbe<-sample(1:7,length(x),replace=T)

  # Grafik erstellen und weitere Elemente
  plot(x,col=brewer.pal(7,"Oranges")[farbe],border=F)

  # Betitelung
  mtext("PLZ Grenzen",side=3,line=-4,adj=0,cex=1.7)
}
map()
