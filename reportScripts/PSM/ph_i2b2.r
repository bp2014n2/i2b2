require(RPostgreSQL)

#source("PSM/ph_utils.r")

executeQuery <- function(query, ...) {
  
  final_query <- sprintf(query, ...)
  print(final_query)
  con <- initializeCRCConnection()
  result <- dbGetQuery(con, final_query)
  destroyCRCConnection(con)
  return(result)
  
}

#local guest vm ip 172.16.19.0
#server ip 54.93.194.65
initializeCRCConnection <- function() {
  drv <- dbDriver("PostgreSQL")
  return(dbConnect(drv, dbname="i2b2", host="172.16.19.0", user="i2b2demodata", password="demouser", port="5432"))
}

destroyCRCConnection <- function(con) {
  
  dbDisconnect(con)
  
}

getConcepts <- function(types=c(), level=3) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from '.*:.{%d}') AS concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_cd SIMILAR TO '%s%%'"
  
  feature_filter <- paste("(", paste(types, collapse="|"), ")", sep="")
  return(executeQuery(strunwrap(queries.features), level, feature_filter)$concept_cd)
}

getObservations <- function(interval, types=c(), level=3, patient_set=-1) {
  feature_filter <- paste("(", paste(types, collapse="|"), ")", sep="")
  return(getObservationsForConcept(interval=interval, concept=feature_filter, level=level, patient_set=patient_set))
}

getObservationsForConcept <- function(interval, concept, level=3, patient_set=-1) {
  interval <- list(start=as.Date(2007-01-01), end=as.Date(2008-01-01))
  queries.observations <- "SELECT patient_num, concept_cd, count(*) AS count
    FROM (
      SELECT patient_num, substring(concept_cd from '.*:.{%d}') AS concept_cd
      FROM i2b2demodata.observation_fact
      WHERE concept_cd IN (
        SELECT concept_cd
        FROM i2b2demodata.concept_dimension
        WHERE concept_cd SIMILAR TO '%s%%')
      AND (start_date >= '%s' AND start_date <= '%s')
      AND (%s
      OR patient_num IN (
        SELECT patient_num
        FROM i2b2demodata.qt_patient_set_collection
        WHERE result_instance_id = %d))) observations
    GROUP BY patient_num, concept_cd"

  # original query with "AND (start_date >= '%s' AND start_date <= '%s')" + interval parameters "interval$start" & interval$end
  #in executeQuery() call
  #interval <- lapply(interval, posixltToPSQLDate)
  return(executeQuery(strunwrap(queries.observations), level, concept, patient_set < 0, patient_set))
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
  queries.concept_cd <- "SELECT DISTINCT substring(concept_cd from '(.*:.{%d})') AS concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_path SIMILAR TO '%s%%'"
  
  return(executeQuery(strunwrap(queries.concept_cd), level, gsub("[\\]", "\\\\\\\\", concept_path))$concept_cd)
}


######################################## from ph_mainscript.r ###################################################

generateFeatureMatrix <- function(interval = list(start=1, end=2), patient_set=-1, features, filter, level=3) {
  patients <- getPatients(patient_set=patient_set)
  observations <- getObservations(types=filter, interval=interval, patient_set=patient_set, level=level)
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd, features)), x=as.numeric(count), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(m)
}