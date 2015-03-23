# ---- code ----
setwd("../../../")
hist_age_extended <- function(ages) {
  histogram <- hist(ages, plot=FALSE, breaks=c(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,200), right=F)

  attach(histogram)
  mean_count <- mean(counts)
  maxVal <- roundUp(max(counts))

  # Setting the layout
  # omi: Outer border
  # mai: Inner border
  # mpg: Abstand Achsenbeschriftung
  par(omi=c(0.65,0.25,0.75,0.75),mai=c(0.3,1.5,0.35,0),mgp=c(3,3,0),
        family="Lato Light", las=1)  

  # Creating graphic
  x<-barplot(counts,names.arg=F,horiz=T,border=NA,xlim=c(0,maxVal),
              col="grey", cex.names=0.85,axes=F)

  
  # Blue background bars
  rect(0,0,maxVal/10*2,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
  rect(maxVal/10*2,0,maxVal/10*4,20.7,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
  rect(maxVal/10*4,0,maxVal/10*6,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
  rect(maxVal/10*6,0,maxVal/10*8,20.7,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
  rect(maxVal/10*8,0,maxVal,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)

  wert2<-c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
  wert2[which.max(counts)] <- max(counts)
  farbe2<-rgb(255,0,210,maxColorValue=255)
  x2<-barplot(wert2,names.arg=F,horiz=T,border=NA,xlim=c(0,100),
                col=farbe2,cex.names=0.85,axes=F,add=T)

  #Grafik beschriften
  for (i in 1:length(counts))
  {
    if (counts[i] > mean_count) 
        {schrift<-"Lato Black"} else {schrift<-"Lato Light"}
    if(i == 1)
      text(maxVal/100*(-2),x[i],paste(0, "-", breaks[i+1]-1),xpd=T,adj=1,cex=0.85,family=schrift)
    if(i == length(counts))
      text(maxVal/100*(-2),x[i],paste(">=", breaks[i]),xpd=T,adj=1,cex=0.85,family=schrift)
    else
      text(maxVal/100*(-2),x[i],paste(breaks[i], "-", breaks[i+1]-1),xpd=T,adj=1,cex=0.85,family=schrift)
    if(counts[i] > maxVal/10) {
      text(counts[i]-(maxVal/100*0.1),x[i],counts[i],xpd=T,adj=1,cex=0.55,family=schrift)
    }
  }

  arrows(mean_count,-0.25,mean_count,20.75,lwd=1.5,length=0,xpd=T,col="skyblue3") 
  arrows(mean_count,-0.25,mean_count,0,lwd=3,length=0,xpd=T)
  arrows(mean_count,20.75,mean_count,21,lwd=3,length=0,xpd=T)
  text(mean_count,22,"Average",adj=0.5,xpd=T,cex=0.65,font=3)
  text(mean_count,21.5,round(mean_count, digits=0)+20,adj=0.5,xpd=T,cex=0.65,family="Lato",font=4)
  text(maxVal/100*(-5.5),21.3,"Age",adj=0.5,xpd=T,cex=0.65,font=3)
  text(maxVal,21.3,"Values are absolute",adj=1,xpd=T,cex=0.65,font=3)
  
  # X-Legend
  mtext(c(0,maxVal/10*2,maxVal/10*4,maxVal/10*6,maxVal/10*8,maxVal),at=c(0,maxVal/10*2,maxVal/10*4,maxVal/10*6,maxVal/10*8,maxVal),1,line=0,cex=0.80)

  # Titles
  mtext("Age Distribution",3,line=1.3,adj=0,cex=1.2,family="Lato Black",outer=T)
  
  if(!is.null(params$limit)) {
    mtext(paste0("Histogram for first ", params$limit, " patients"),3,line=0,adj=0,cex=0.9,outer=T)
  } else {
    mtext(paste0("Histogram for all patients"),3,line=0,adj=0,cex=0.9,outer=T)
  }
  mtext("Elsevier Health Analytics",1,line=1,adj=1.0,cex=0.65,outer=T,font=3)
}

age_histogram_main <- function() {
     if(!is.null(params$limit)){
     patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, params$limit)
   } else {
     patients <- i2b2$crc$getPatients(model.patient_set)
   } 
  # patients$age_in_years_num = age(as.Date(patients$birth_date), Sys.Date())
  hist_age_extended(age(as.Date(patients$birth_date), Sys.Date()))
}

age_histogram_main()
