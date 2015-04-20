# ---- code ----
source("../../lib/style.r")

frequence_of_visits <- function(patients) {
 
  par(
    mai=c(1,1,0.5,0.5),         # Outer border (bottom, top, left, right)
    omi=c(0.65,0.25,0.75,0.75), # Inner border
    family="Lato",              # Font 
    las=1,                      # Style of axle labels (horizontal) 
    col=darkGray
  )

  # Coverting visit date to timestamp
  patients$visitsWithObservation$visitDate <- strptime(     
    unlist(patients$visitsWithObservation[1], use.names=F),   # vector of all visits
    "%Y-%m-%d %H:%M:%S"                                       # format how to parse
  )

  # Absolute count
  patients$visitsWithObservation$abs_counts <- as.numeric(unlist(c(patients$visitsWithObservation[2])))

  # Calculate relative count for with observation (number of visits) / (number of patients)
  patients.withObservation.relative_visits_counts <- unlist(
    lapply(
      patients$visitsWithObservation$abs_counts,
      FUN = function(r) {
        r / patients$withObservation
      }
    )
  )

  visits_per_quarter <- quarters(patients$visitsWithObservation$visitDate)
  years <- strftime(patients$visitsWithObservation$visitDate, "%Y")
  dd <- data.frame(visits_per_quarter, years, patients.withObservation.relative_visits_counts)

  p.with.agg <- aggregate(patients.withObservation.relative_visits_counts ~ visits_per_quarter + years, dd, FUN = sum)
  p.with.agg$date <- as.POSIXct(paste(p.with.agg$years, as.numeric(substr(p.with.agg$visits_per_quarter,2,2))*3, "01", sep = "-"))

  # Coverting visit date to timestamp
  patients$visitsWithoutObservation$visitDate <- strptime(
    unlist(patients$visitsWithoutObservation[1], use.names=F),  # vector of all visits
    "%Y-%m-%d %H:%M:%S"                                         # format how to parse
  )

  # Absolute count
  patients$visitsWithoutObservation$abs_counts <- as.numeric(unlist(c(patients$visitsWithoutObservation[2])))

  # Calculate relative count for without observation (number of visits) / (number of patients)
  patients.withoutObservation.relative_visits_counts <- unlist(
    lapply(
      patients$visitsWithoutObservation$abs_counts, 
      FUN = function(r) {
        r / patients$withoutObservation
      }
    )
  )

  visits_per_quarter <- quarters(patients$visitsWithoutObservation$visitDate)
  years <- strftime(patients$visitsWithoutObservation$visitDate, "%Y")
  dd <- data.frame(visits_per_quarter, years, patients.withoutObservation.relative_visits_counts)

  p.without.agg <- aggregate(patients.withoutObservation.relative_visits_counts ~ visits_per_quarter + years, dd, FUN = sum)
  p.without.agg$date <- as.POSIXct(paste(p.without.agg$years, as.numeric(substr(p.without.agg$visits_per_quarter,2,2))*3, "01", sep = "-"))
  
  plot(p.with.agg$date,p.with.agg$patients.withObservation.relative_visits_counts,type="n",xlab="",ylab="relative count")

  # axis(2,col=par("bg"),col.ticks="grey81", lwd.ticks=0.5,tck=-0.025)
  lines(p.with.agg$date,p.with.agg$patients.withObservation.relative_visits_counts,type="l",col=baseColor,lwd=3,xpd=T)
  lines(p.without.agg$date,p.without.agg$patients.withoutObservation.relative_visits_counts,type="l",col=accentColor[1],lwd=3)
  text(head(p.with.agg$date, 1),max(p.without.agg$patients.withoutObservation.relative_visits_counts, p.with.agg$patients.withObservation.relative_visits_counts)*0.9,"Mit Knorpelkrankheiten",adj=0,cex=1,col=baseColor)
  text(head(p.with.agg$date, 1),max(p.without.agg$patients.withoutObservation.relative_visits_counts, p.with.agg$patients.withObservation.relative_visits_counts)*0.85,"Ohne Knorpelkrankheiten",adj=0,cex=1,col=accentColor[1])
  beginn<-c(head(p.with.agg$date, 1)); ende<-c(tail(p.with.agg$date, 1))
  farbe<-c(set.alpha(baseColor, 0.5))
  for(i in 1:length(beginn)) {
    xx<-c(p.with.agg$date,rev(p.with.agg$date)); yy<-c(p.with.agg$patients.withObservation.relative_visits_counts,rev(p.without.agg$patients.withoutObservation.relative_visits_counts))
    polygon(xx,yy,col=farbe[i],border=F)
  }
  
  # Betitelung
  mtext("Frequenz der Arztbesuche",3,line=1.3,adj=0,family="Lato Black",cex=1.2,outer=T)
  if(!is.null(params$icd)) {
     mtext(paste0("Analysierte ICD: ", params$icd),3,line=0,adj=0,cex=0.9,outer=T)
  } else {
     mtext("\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\",3,line=0,adj=0,cex=0.9,outer=T)
  }
  mtext("Elsevier Health Analytics",1,line=3,adj=1,cex=0.65,font=3)
}  

frequence_of_visits_main <- function() {
  patients <- matrix()
  if(is.null(params$icd)  || nchar(params$icd) == 0) {
    patients$visitsWithObservation <- i2b2$crc$getVisitCountForPatientsWithObservation(model.patient_set)
    patients$visitsWithoutObservation <- i2b2$crc$getVisitCountForPatientsWithoutObservation(model.patient_set)
    patients$withObservation <- i2b2$crc$getPatientsCountWithObservation(model.patient_set)
    patients$withoutObservation <- i2b2$crc$getPatientsCountWithoutObservation(model.patient_set)
  } else {
    patients$visitsWithObservation <- i2b2$crc$getVisitCountForPatientsWithObservation(patient_set=model.patient_set, concepts=c(params$icd))
    patients$visitsWithoutObservation <- i2b2$crc$getVisitCountForPatientsWithoutObservation(patient_set=model.patient_set, concepts=c(params$icd))
    patients$withObservation <- i2b2$crc$getPatientsCountWithObservation(patient_set=model.patient_set, concept=params$icd)
    patients$withoutObservation <- i2b2$crc$getPatientsCountWithoutObservation(patient_set=model.patient_set, concept=params$icd)
  }
  frequence_of_visits(patients)
}

frequence_of_visits_main()
