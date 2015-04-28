# ---- code ----
# suppressMessages(library(maptools))
# suppressMessages(library(rgdal))
suppressMessages(library(sp))
suppressMessages(library(RColorBrewer))
# gpclibPermit()

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
  
  # Generate map data and save to file [already saved to map_data.RData]
  # map_data<-readShapeSpatial(
  #  "/home/ubuntu/i2b2/GIRIXScripts/ReportGenerator/diagrams/map/post_pl.shp",
  #  IDvar="PLZ99", 
  #  proj4string=CRS("+proj=longlat")
  # )
  # 
  # map_data<-spTransform(map_data,CRS=CRS("+proj=merc"))
  # map_data$zip <- as.numeric(substr(map_data$PLZ99, 1, 2))
  # 
  # slot(map_data, "polygons") <- slot(unionSpatialPolygons(map_data, map_data$zip), "polygons")
  # 
  # postals <- unique(slot(map_data, "data")$zip)
  # slot(map_data, "plotOrder") <- seq(1,length(postals))

  # polygon_data <- data.frame(zip=as.numeric(sapply(slot(map_data, "polygons"), function(i) slot(i, "ID"))))
  # slot(map_data, "data") <- polygon_data
  # 
  # save(map_data, file="map_data.RData")

  load("../diagrams/map/map_data.RData")

  color<-sample(1:7,length(map_data),replace=T)

  patient_data_tmp <- i2b2$crc$getPatientsWithPlz(model.patient_set)
  patient_data_tmp$zip <- as.numeric(substring(patient_data_tmp$statecityzip_path, nchar(patient_data_tmp$statecityzip_path)-2, nchar(patient_data_tmp$statecityzip_path)-1))
  patient_data <- na.omit(patient_data_tmp)
  patient_data$counts <- as.numeric(patient_data$counts)

  zip_data <- aggregate(x=patient_data$counts, by=list(patient_data$zip), FUN=sum)
  zip_data$zip <- as.numeric(zip_data[,1])

  tmp_data <- merge(x=slot(map_data, "data"), y=zip_data, by="zip", all.x=T) 
  tmp_data$x[is.na(tmp_data$x)] <- 0 # Replace NA with 0
  slot(map_data, "data") <- tmp_data

  tmp_data$zip <- as.character(tmp_data$zip)
  sorted_data_alphanumerical <- tmp_data[order(tmp_data$zip),]$x

  color_nr <- cut(sorted_data_alphanumerical, c(0,10,1000,2000,4000,10000,100000),dig.lab=10)
  colors<-brewer.pal(6, "Oranges")

  if(!is.null(params$plzFilter) && nchar(params$plzFilter) == 2) {
    map_data<-subset(map_data,substr(map_data$PLZ99,1,2)==as.numeric(params$plzFilter))
  }

  # Plot
  plot(map_data,col=colors[color_nr],border = "black", lwd = 1)

  # Legend
  legend("bottomleft", levels(color_nr), cex=0.95,border=F,bty="n",fill=colors)
}
map()
