require(RPostgreSQL)

source("utils.r")
source("i2b2.config.r")

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
  return(dbConnect(drv, dbname=db.name, host=db.host, user=db.username, password=db.password, port=db.port))
}

destroyCRCConnection <- function(con) {
  
  dbDisconnect(con)
  
}

getConcepts <- function(types=c(), level=3) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from 1 for %d) AS concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE (%s)"
  
  concepts <- paste(types, ':', sep='')
  concept_condition <- paste(paste("concept_cd LIKE '", concepts, "%'", sep=""), collapse=" OR ")
  return(executeQuery(strunwrap(queries.features), level + 4, concept_condition)$concept_cd)
}

getConceptName <- function(concept_cd) {
  query <- "SELECT name_char
    FROM i2b2demodata.concept_dimension
    WHERE concept_cd LIKE '%s%%'
    ORDER BY concept_cd"
  return(executeQuery(strunwrap(query), concept_cd)[1,])
}

getObservations <- function(interval, types=c(), level=3, patient_set=-1) {
  concepts <- paste(types, ':', sep='')
  return(getObservationsForConcept(interval=interval, concepts=concepts, level=level, patient_set=patient_set))
}

getObservationsForConcept <- function(interval, concepts, level=3, patient_set=-1) {
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
  return(executeQuery(strunwrap(queries.observations), level + 4, concept_condition, interval$start, interval$end, patient_set < 0, patient_set))
}

getPatients <- function(patient_set=-1) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d)"
  
  return(executeQuery(strunwrap(queries.patients), patient_set < 0, patient_set))
}

getPatientSetDescription <- function(patient_set) {
  queries.patient_set <- "SELECT description
    FROM i2b2demodata.qt_query_result_instance
    WHERE result_instance_id = %d"
  
  return(executeQuery(strunwrap(queries.patient_set), patient_set)$description)
}

getConceptCd <- function(concept_path) {
  level <- countCharOccurrences('\\\\', concept_path) - 2
  queries.concept_cd <- "SELECT DISTINCT substring(concept_cd from 1 for %d) AS concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_path LIKE '%s%%'"
  
  return(executeQuery(strunwrap(queries.concept_cd), level + 4, gsub("[\\]", "\\\\\\\\", concept_path))$concept_cd)
}