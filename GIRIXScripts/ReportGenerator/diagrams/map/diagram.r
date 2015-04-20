# ---- code ----
suppressMessages(library(maptools))
suppressMessages(library(rgdal))
library(RColorBrewer)
gpclibPermit()

map <- function(){
  options(scipen=10) # don't convert into exponential format

  par(
    mfrow = c(1,2),
    mar=c(0,0,0,0),
    oma=c(1,1,1,0), 
    mfcol=c(1,1),
    family="Lato",
    las=1
  )

  # Daten einlesen und Grafik vorbereiten
  map_data<-readShapeSpatial(
    "/home/ubuntu/i2b2/GIRIXScripts/ReportGenerator/diagrams/map/post_pl.shp",
    IDvar="PLZ99", 
    proj4string=CRS("+proj=longlat")
  )

  map_data<-spTransform(map_data,CRS=CRS("+proj=merc"))

  color<-sample(1:7,length(map_data),replace=T)

  patient_data <- i2b2$crc$getPatientsWithPlz()
  patient_data$zip <- substring(patient_data$statecityzip_path, nchar(patient_data$statecityzip_path)-2, nchar(patient_data$statecityzip_path)-1) 

  zip_data <- aggregate(x=patient_data$count, by=list(patient_data$zip), FUN=sum)
  zip_data$zip <- as.numeric(zip_data[,1])

  map_data$zip <- as.numeric(substr(map_data$PLZ99, 1, 2))
  map_data <- merge(x=map_data, y=zip_data, by="zip") 

  color_nr <- cut(map_data$x, c(0,1000,2000,4000,10000,100000))
  colors<-brewer.pal(6, "Oranges")

  if(!is.null(params$plzFilter) && nchar(params$plzFilter) == 2) {
    map_data<-subset(map_data,substr(map_data$PLZ99,1,2)==params$plzFilter)
  }

  # Plot
  plot(map_data,col=colors[color_nr],border=F)

  # Plot borders
  map_data.union <- unionSpatialPolygons(map_data, map_data$zip)
  plot(map_data.union, add = TRUE, border = "black", lwd = 1)

  # Legend
  legend("bottomleft", levels(color_nr), cex=0.95,border=F,bty="n",fill=colors)
}
map()
