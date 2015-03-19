i2b2$crc <- list()

source("lib/i2b2.crc.config.r")

executeCRCQuery <- function(query, ...) {
  return(executeQuery(i2b2$crc$db, query, ...))
}
 
i2b2$crc$getConcepts <- function(concepts=c(), level=3) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from 1 for %d) AS concept_cd
  FROM i2b2demodata.concept_dimension
  WHERE (%s)"
  
  concept_condition <- paste(paste("concept_cd LIKE '", concepts, "%'", sep=""), collapse=" OR ")
  return(executeCRCQuery(queries.features, level + 4, concept_condition)$concept_cd)
}

i2b2$crc$getObservations <- function(interval, concepts=c(), level=3, patient_set=-1) {
  queries.observations <- "SELECT patient_num, concept_cd, count(*) AS count
  FROM (
    SELECT patient_num, substring(concept_cd from 1 for %d) AS concept_cd
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE (%s))
    AND (start_date >= '%s' AND start_date <= '%s')
    AND (%s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))) observations
  GROUP BY patient_num, concept_cd"
  concept_condition <- paste(paste("concept_cd LIKE '", concepts, "%'", sep=""), collapse=" OR ")
  interval <- lapply(interval, posixltToPSQLDate)
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, interval$start, interval$end, patient_set < 0, patient_set))
}

i2b2$crc$getObservationsForConcept <- function(interval, concept.path, patient_set=-1) {
  queries.observations <- "SELECT patient_num, 'target' as concept_cd, count(*) AS count
  FROM (
    SELECT patient_num
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE concept_path LIKE '%s%%')
    AND (start_date >= '%s' AND start_date <= '%s')
    AND (%s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))) observations
  GROUP BY patient_num"
  interval <- lapply(interval, posixltToPSQLDate)
  return(executeCRCQuery(queries.observations, escape(concept.path), interval$start, interval$end, patient_set < 0, patient_set))
}

i2b2$crc$getPatients <- function(patient_set=-1) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d)"
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set))
}

i2b2$crc$getPatientSetDescription <- function(patient_set) {
  queries.patient_set <- "SELECT description
    FROM i2b2demodata.qt_query_result_instance
    WHERE result_instance_id = %d"
  
  return(executeCRCQuery(queries.patient_set, patient_set)$description)
}


i2b2$crc$getPatientsLimitable <- function(patients_limit) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE patient_num < %d"
  
  return(executeCRCQuery(queries.patients, patients_limit))
}

i2b2$crc$getObservationsLimitable <- function(interval, concepts=c(), level=3, patients_limit) {
  queries.observations <- "SELECT patient_num, concept_cd, count(*) AS count
  FROM (
    SELECT patient_num, substring(concept_cd from 1 for %d) AS concept_cd
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE (%s))
    AND (start_date >= '%s' AND start_date <= '%s')
    AND patient_num < %d) observations
  GROUP BY patient_num, concept_cd"
  concept_condition <- paste(paste("concept_cd LIKE '", concepts, "%'", sep=""), collapse=" OR ")
  interval <- lapply(interval, posixltToPSQLDate)
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, interval$start, interval$end, patients_limit))
}
