require(RPostgreSQL)

source("utils.r")

executeQuery <- function(query, ...) {
  
  final_query <- sprintf(query, ...)
  print(final_query)
  con <- initializeCRCConnection()
  result <- dbGetQuery(con, final_query)
  destroyCRCConnection(con)
  return(result)
  
}

initializeCRCConnection <- function() {
  drv <- dbDriver("PostgreSQL")
  return(dbConnect(drv, dbname="i2b2", host="localhost", user="i2b2demodata", password="demouser", port="5432"))
}

destroyCRCConnection <- function(con) {
  
  dbDisconnect(con)
  
}

getConcepts <- function(types=c(), level=3) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from '(%s.{%d})') AS concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_cd SIMILAR TO '%s%%'"
  
  feature_filter <- paste("(", paste(types, collapse="|"), "):", sep="")
  return(executeQuery(strunwrap(queries.features), feature_filter, level, feature_filter)$concept_cd)
}

getObservations <- function(dates, types=c(), level=3, patient_set=-1) {
  feature_filter <- paste("(", paste(types, collapse="|"), "):", sep="")
  return(getObservationsForConcept(dates=dates, types=types, concept=feature_filter, level=level, patient_set=patient_set))
}

getObservationsForConcept <- function(dates, types=c(), concept, level=3, patient_set=-1) {
  queries.observations <- "SELECT patient_num, concept_cd, count(*) AS count
    FROM (
      SELECT patient_num, substring(concept_cd from '(%s.{%d})') AS concept_cd
      FROM i2b2demodata.observation_fact
      WHERE concept_cd IN (
        SELECT concept_cd
        FROM i2b2demodata.concept_dimension
        WHERE concept_cd SIMILAR TO '%s%%')
      AND (start_date >= '%sT00:00:00' AND start_date <= '%sT00:00:00')
      AND (%s
      OR patient_num IN (
        SELECT patient_num
        FROM i2b2demodata.qt_patient_set_collection
        WHERE result_instance_id = %d))) observations
    GROUP BY patient_num, concept_cd"
  
  dates <- sapply(dates, posixltToPSQLDate)
  feature_filter <- paste("(", paste(types, collapse="|"), "):", sep="")
  return(executeQuery(strunwrap(queries.observations), feature_filter, level, concept, dates[1], dates[2], patient_set == -1, patient_set))
}

getPatients <- function(patient_set=-1) {
  queries.patients <- "SELECT patient_num
    FROM i2b2demodata.patient_dimension
    WHERE %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d)"
  
  return(executeQuery(strunwrap(queries.patients), patient_set == -1, patient_set)$patient_num)
}

getPatientSetDescription <- function(patient_set) {
  queries.patient_set <- "SELECT description
    FROM i2b2demodata.qt_query_result_instance
    WHERE result_instance_id = %d"
  
  return(executeQuery(strunwrap(queries.patient_set), patient_set)$description)
}

getConceptCd <- function(concept_path) {
  queries.concept_cd <- "SELECT concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_path LIKE '%s'"
  
  return(executeQuery(strunwrap(queries.concept_cd), gsub("[\\]", "\\\\\\\\", concept_path))$concept_cd)
}