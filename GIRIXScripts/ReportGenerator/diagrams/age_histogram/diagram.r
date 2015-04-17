# ---- code ----
source("../../lib/style.r")

hist_age_extended <- function(patients) {
  # The only needed information from patients
  ages <- patients$age_in_years_num

  # Break the ages down to a histogram with specified age breaks
  ages.hist <- hist(
    ages,             # values for histogram
    plot=F,           # should not plottet, only data generated
    breaks=c(0,5,10,15,20,25,30,35,40,45,50,55,60,65,70,75,80,200), 
    right=F           # intervals should be right closed
  )
 
  ages.hist$mean <- mean(ages.hist$counts)
  ages.hist$max <- utils.roundUp(max(ages.hist$counts))

  # Setting the layout
  # omi: Outer border
  # mai: Inner border
  # mpg: Abstand Achsenbeschriftung
  par(
    omi=c(0.65,0.25,0.75,0.75), # Outer border
    mai=c(0.3,1.5,0.35,0),      # Inner border
    mgp=c(0,0,0),               # Space axle text
    family="Lato",              # Font
    las=1                       # Style of axle labels (horizontal)
  )  

  # Creating graphic
  x<-barplot(
    ages.hist$counts,
    names.arg=F,
    horiz=T,
    border=NA,
    xlim=c(0,ages.hist$max),
    col="grey", 
    cex.names=0.85,axes=T
  )

  
  # Blue background bars
  rect(0,0,ages.hist$max/10*2,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
  rect(ages.hist$max/10*2,0,ages.hist$max/10*4,20.7,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
  rect(ages.hist$max/10*4,0,ages.hist$max/10*6,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)
  rect(ages.hist$max/10*6,0,ages.hist$max/10*8,20.7,col=rgb(191,239,255,120,maxColorValue=255),border=NA)
  rect(ages.hist$max/10*8,0,ages.hist$max,20.7,col=rgb(191,239,255,80,maxColorValue=255),border=NA)

  wert2<-c(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
  wert2[which.max(ages.hist$counts)] <- max(ages.hist$counts)
  farbe2<-rgb(255,0,210,maxColorValue=255)
  x2<-barplot(wert2,names.arg=F,horiz=T,border=NA,xlim=c(0,100),
                col=farbe2,cex.names=0.85,axes=F,add=T)

  #Grafik beschriften
  for (i in 1:length(ages.hist$counts))
  {
    if (ages.hist$counts[i] > ages.hist$mean) 
        {schrift<-"Lato"} else {schrift<-"Lato"}
    if(i == 1)
      text(ages.hist$max/100*(-2),x[i],paste(0, "-", ages.hist$breaks[i+1]-1),xpd=T,adj=1,cex=0.85,family=schrift)
    if(i == length(ages.hist$counts))
      text(ages.hist$max/100*(-2),x[i],paste(">=", ages.hist$breaks[i]),xpd=T,adj=1,cex=0.85,family=schrift)
    else
      text(ages.hist$max/100*(-2),x[i],paste(ages.hist$breaks[i], "-", ages.hist$breaks[i+1]-1),xpd=T,adj=1,cex=0.85,family=schrift)
    if(ages.hist$counts[i] > ages.hist$max/10) {
      text(ages.hist$counts[i]-(ages.hist$max/100*0.1),x[i],ages.hist$counts[i],xpd=T,adj=1,cex=0.55,family=schrift)
    }
  }

  arrows(ages.hist$mean,-0.25,ages.hist$mean,20.75,lwd=1.5,length=0,xpd=T,col="skyblue3") 
  arrows(ages.hist$mean,-0.25,ages.hist$mean,0,lwd=3,length=0,xpd=T)
  arrows(ages.hist$mean,20.75,ages.hist$mean,21,lwd=3,length=0,xpd=T)
  text(ages.hist$mean,22,"Average",adj=0.5,xpd=T,cex=0.65,font=3)
  text(ages.hist$mean,21.5,round(ages.hist$mean, digits=0)+20,adj=0.5,xpd=T,cex=0.65,family="Lato",font=4)
  text(ages.hist$max/100*(-5.5),21.3,"Age",adj=0.5,xpd=T,cex=0.65,font=3)
  text(ages.hist$max,21.3,"Values are absolute",adj=1,xpd=T,cex=0.65,font=3)
  
  # X-Legend
  mtext(c(0,ages.hist$max/10*2,ages.hist$max/10*4,ages.hist$max/10*6,ages.hist$max/10*8,ages.hist$max),at=c(0,ages.hist$max/10*2,ages.hist$max/10*4,ages.hist$max/10*6,ages.hist$max/10*8,ages.hist$max),1,line=0,cex=0.80)

  # Titles
  mtext("Age Distribution",3,line=1.3,adj=0,cex=1.2,family="Lato",outer=T)
  
  if(!is.null(params$limit)) {
    mtext(paste0("Histogram for first ", params$limit, " patients"),3,line=0,adj=0,cex=0.9,outer=T)
  } else {
    mtext(paste0("Histogram for all patients"),3,line=0,adj=0,cex=0.9,outer=T)
  }
  mtext("Elsevier Health Analytics",1,line=1,adj=1.0,cex=0.65,outer=T,font=3)
}

age_histogram_main <- function() {
  # Check if limit is set as a parameter
  if(!is.null(params$limit)){
    # Patients with limit
    patients <- i2b2$crc$getPatientsWithLimit(model.patient_set, params$limit)
  } else {
    # All patients
    patients <- i2b2$crc$getPatients(model.patient_set)
  }
  # age_in_years_num is not set in database so calculate it
  patients$age_in_years_num = age(as.Date(patients$birth_date), Sys.Date())
  # create the diagram
  hist_age_extended(patients)
}

age_histogram_main()
