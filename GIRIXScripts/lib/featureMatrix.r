require(Matrix)

time.query <<- 0

generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd_sub, features)), x=as.numeric(counts), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(m)
}

generateFeatureMatrix <- function(interval, patients, patient_set=-1, features, filter, level=3, addFeatures=c()) {
  
  time.start <- proc.time()

  patients <<- patients
  
  observations <<- i2b2$crc$getObservations(concepts=filter, interval=interval, patient_set=patient_set, level=level)
  if(length(addFeatures < 0)) {
    for(i in 1:length(addFeatures)) {
      addFeature <- addFeatures[i]
      obs <- i2b2$crc$getObservationsForConcept(concept.path=addFeature, interval=interval, patient_set=patient_set)
      name <- names(addFeatures)[i]
      obs$concept_cd_sub <- name
      features <- append(features, name)
      observations <- rbind2(observations, obs)
    }
  }
  #observations <<- observations[observations[,"patient_num"] %in% patients,]
  #rownames(observations) <- 1:nrow(observations)
  
  time.end <- proc.time()
  
  time.query <<- time.query + sum(c(time.end-time.start)[3])
  
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), interval$end))
  return(feature_matrix)
}

generateFeatureMatrixDependingOnTreatment <- function(intervalLength.Years = 3, timeOfObservation, patients, patient_set=-1, features, filter, level=3, treatment.path, addFeatures=c()) {
  
  time.start <- proc.time()

  patients <<- patients
  
  observations <<- i2b2$crc$getObservationsDependingOnTreatment(treatment.path = treatment.path, concepts=filter, 
                                                                intervalLength.Years = intervalLength.Years, patient_set=patient_set, level=level)
  if(length(addFeatures < 0)) {
    for(i in 1:length(addFeatures)) {
      addFeature <- addFeatures[i]
      obs <- i2b2$crc$getObservationsDependingOnTreatmentForConcept(concept.path=addFeature, intervalLength.Years=3, patient_set=patient_set)
      name <- names(addFeatures)[i]
      obs$concept_cd_sub <- name
      features <- append(features, name)
      observations <- rbind2(observations, obs)
    }
  }



  #observations <<- observations[observations[,"patient_num"] %in% patients,]
  #rownames(observations) <- 1:nrow(observations)
  
  time.end <- proc.time()
  
  time.query <<- time.query + sum(c(time.end-time.start)[3])
  
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), timeOfObservation))
  return(feature_matrix)
}


generateTargetVector <- function(interval, patients, patient_set=-1, concept.path) {
  
  time.start <- proc.time()
  
  observations <- i2b2$crc$getObservationsForConcept(concept.path=concept.path, interval=interval, patient_set=patient_set)
  observations$concept_cd_sub <- 'target'
  
  time.end <- proc.time()
  
  time.query <<- time.query + sum(c(time.end-time.start)[3])
  
  target_matrix <- generateObservationMatrix(observations, c('target'), patients$patient_num)
  return(sign(target_matrix[,1]))
}