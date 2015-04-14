# functions for preparation of data requested from database (no queries here)

source("i2b2.r")

# used by AutoPSM, to do: unite with generateFeatureMatrixFromPatientSet 
DataPrep.generateFeatureMatrix <- function(patients_limit, filter=c("ATC:", "ICD:"), level=3) {
  features <- i2b2$crc$getConcepts(concepts=filter, level=level)

  patients <- i2b2$crc$getPatientsLimitable(patients_limit=patients_limit)
  observations <- i2b2$crc$getObservationsLimitable(concepts=filter, patients_limit=patients_limit, level=level)
  feature_matrix <- DataPrep.generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

# used by PSM, to do: unite with generateFeatureMatrix
# not limitable
DataPrep.generateFeatureMatrixFromPatientSet <- function(patient_set, interval, filter=c("ATC:", "ICD:"), level=3) {
  features <- i2b2$crc$getConcepts(concepts=filter, level=level)

  patients <- i2b2$crc$getPatients(patient_set = patient_set)
  observations <- i2b2$crc$getObservations(interval=interval, patient_set= patient_set, concepts=filter, level=level)
  feature_matrix <- DataPrep.generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

DataPrep.generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), 
                                       j=as.numeric(match(concept_cd_sub, features)), 
                                       x=as.numeric(counts), dims=c(length(patients), 
                                       length(features)), dimnames=list(patients, features)))  
  return(m)
}