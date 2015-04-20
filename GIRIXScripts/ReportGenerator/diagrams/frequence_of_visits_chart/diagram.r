# ---- code ----
source("../../lib/style.r")

frequence_of_visits <- function(patients) {
 
  par(
    mai=c(1,1,0,0.5),           # Outer border
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

  quarters_of_visits <- quarters(patients$visitsWithObservation$visitDate)
  years_of_visits <- strftime(patients$visitsWithObservation$visitDate, "%Y")
  dd <- data.frame(quarters_of_visits, years_of_visits, patients.withObservation.relative_visits_counts)

  patients.withObservation.aggregated <- setNames(
    aggregate(patients.withObservation.relative_visits_counts ~ quarters_of_visits + years_of_visits, dd, FUN = sum), 
    c('quarter', 'year', 'relative_visit_counts')
  )

  patients.withObservation.aggregated$date <- as.POSIXct(
    paste(                                                                   # Recreate date strings
      patients.withObservation.aggregated$year,                              # Year
      as.numeric(substr(patients.withObservation.aggregated$quarter,2,2))*3, # Quarters to months conversion
      "01",                                                                  # Day
      sep = "-"
    )
  )

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

  quarters_of_visits <- quarters(patients$visitsWithoutObservation$visitDate)
  years_of_visits <- strftime(patients$visitsWithoutObservation$visitDate, "%Y")
  dd <- data.frame(quarters_of_visits, years_of_visits, patients.withoutObservation.relative_visits_counts)

  patients.withoutObservation.aggregated <- setNames(
    aggregate(patients.withoutObservation.relative_visits_counts ~ quarters_of_visits + years_of_visits, dd, FUN = sum), 
    c('quarter', 'year', 'relative_visit_counts')
  )

  patients.withoutObservation.aggregated$date <- as.POSIXct(
    paste(                                                                      # Recreate date strings
      patients.withoutObservation.aggregated$year,                              # Year
      as.numeric(substr(patients.withoutObservation.aggregated$quarter,2,2))*3, # Quarters to months conversion
      "01",                                                                     # Day
      sep = "-"
    )
  )

  # Plot
  plot(
    patients.withObservation.aggregated$date,
    patients.withObservation.aggregated$relative_visit_counts,
    type="n",
    xlab="",
    ylab="relative count"
  )

  # Line for patients with overvation
  lines(
    patients.withObservation.aggregated$date,
    patients.withObservation.aggregated$relative_visit_counts,
    type="l",
    col=baseColor,
    lwd=3,
    xpd=T
  )
  
  # Line for patients without observation
  lines(
    patients.withoutObservation.aggregated$date,
    patients.withoutObservation.aggregated$relative_visit_counts,
    type="l",
    col=accentColor[1],
    lwd=3
  )

  if(is.null(params$icdName)){
    icdText <- "M94 Sonstige Knorpelkrankheiten"
  } else {
    icdText <- params$icdName
  }

  text(
    head(patients.withObservation.aggregated$date, 1),
    max(patients.withoutObservation.aggregated$relative_visit_counts, patients.withObservation.aggregated$relative_visit_counts)*0.9,
    paste("With", icdText),
    adj=0,
    cex=1,
    col=baseColor
  )

  text(
    head(patients.withObservation.aggregated$date, 1),
    max(patients.withoutObservation.aggregated$relative_visit_counts, patients.withObservation.aggregated$relative_visit_counts)*0.85,
    paste("Without", icdText),
    adj=0,
    cex=1,
    col=accentColor[1]
  )

  # Color space between lines
  try({
    beginn<-c(head(patients.withObservation.aggregated$date, 1))
    farbe<-c(set.alpha(baseColor, 0.5))
    for(i in 1:length(beginn)) {
      xx <- c(
        patients.withObservation.aggregated$date,
        rev(patients.withObservation.aggregated$date)
      )
      yy <- c(
        patients.withObservation.aggregated$relative_visit_counts,
        rev(patients.withoutObservation.aggregated$relative_visit_counts)
      )
      polygon(xx,yy,col=farbe[i],border=F)
    }
   }, T) 

  # Footer
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
