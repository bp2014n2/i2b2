i2b2$crc <- list()

source("i2b2.crc.config.r")

executeCRCQuery <- function(query, ...) {
  return(executeQuery(i2b2$crc$db, query, ...))
}
 
i2b2$crc$getConcepts <- function(concepts=c(), level=3) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from 1 for %d) AS concept_cd_sub
  FROM i2b2demodata.concept_dimension
  WHERE (%s)"
  
  concept_condition <- paste(paste("concept_path LIKE '", escape(concepts), "%'", sep=""), collapse=" OR ")
  return(executeCRCQuery(queries.features, level + 4, concept_condition)$concept_cd_sub)
}

i2b2$crc$getObservations <- function(interval, concepts=c(), level=3, patient_set=-1) {
  queries.observations <- "SELECT patient_num, concept_cd_sub, count(*) AS counts
  FROM (
    SELECT patient_num, substring(concept_cd from 1 for %d) AS concept_cd_sub
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE (%s))
    AND (start_date >= '%s' AND start_date <= '%s')
    AND (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))) observations
  GROUP BY patient_num, concept_cd_sub"
  concept_condition <- paste(paste("concept_path LIKE '", escape(concepts), "%'", sep=""), collapse=" OR ")
  interval <- lapply(interval, posixltToPSQLDate)
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, interval$start, interval$end, patient_set < 0, patient_set))
}

i2b2$crc$getObservationsForConcept <- function(interval, concept.path, patient_set=-1) {
  queries.observations <- "SELECT patient_num, 'target' as concept_cd_sub, count(*) AS counts
  FROM (
    SELECT patient_num
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.%s
      WHERE %s %s %s)
    AND (start_date >= '%s' AND start_date <= '%s')
    AND (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))) observations
  GROUP BY patient_num"
  interval <- lapply(interval, posixltToPSQLDate)
  lookup <<- i2b2$ont$getTableAndColumn(concept.path)
  table <- lookup$c_tablename
  column <- lookup$c_columnname
  operator <- lookup$c_operator
  parameter <- ifelse(lookup$c_columndatatype == 'T', paste0("'", escape(concept.path), "%'"), concept.path)
  return(executeCRCQuery(queries.observations, table, column, operator, parameter, interval$start, interval$end, patient_set < 0, patient_set))
}

i2b2$crc$getPatients <- function(patient_set=-1) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))"
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set))
}

i2b2$crc$getPatientSetDescription <- function(patient_set) {
  queries.patient_set <- "SELECT description
    FROM i2b2demodata.qt_query_result_instance
    WHERE result_instance_id = %d"
  
  return(executeCRCQuery(queries.patient_set, patient_set)$description)
}

i2b2$crc$getPatientsWithLimit <- function(patient_set=-1, limit=100) {
  queries.patients <- paste("SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d)
    LIMIT ", limit)
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set))
}

i2b2$crc$getPatientsLimitable <- function(patients_limit) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE patient_num < %d"
  
  return(executeCRCQuery(queries.patients, patients_limit))
}

i2b2$crc$getObservationsLimitable <- function(interval, concepts=c(), level=3, patients_limit) {
  queries.observations <- "SELECT patient_num, concept_cd_sub, count(*) AS counts
  FROM (
    SELECT patient_num, substring(concept_cd from 1 for %d) AS concept_cd_sub
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE (%s))
    AND patient_num < %d) observations
  GROUP BY patient_num, concept_cd_sub"
  concept_condition <- paste(paste("concept_cd LIKE '", concepts, "%'", sep=""), collapse=" OR ")
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, patients_limit))
}

i2b2$crc$getVisitCountForPatientsWithoutObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\')) {
  queries.visitcount <- "SELECT visit_dimension.start_date, count(*) as counts
  FROM i2b2demodata.visit_dimension
  WHERE visit_dimension.patient_num NOT IN
   (SELECT patient_num
     FROM (
       SELECT patient_num
       FROM i2b2demodata.observation_fact
       WHERE concept_cd IN (
         SELECT concept_cd
         FROM i2b2demodata.concept_dimension
         WHERE %s)
     GROUP BY patient_num) patients)
  AND (%s OR
      visit_dimension.patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))
  GROUP BY visit_dimension.start_date
  ORDER BY visit_dimension.start_date"
  
  concept_condition <- paste("concept_path LIKE '", concepts, "%'", sep="")
  return(executeCRCQuery(queries.visitcount, concept_condition, patient_set < 0, patient_set))
}

i2b2$crc$getPatientsCountWithoutObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\')) {
  queries.patientcount <- "SELECT COUNT(DISTINCT patient_num) as counts 
  FROM i2b2demodata.patient_dimension
  WHERE patient_num NOT IN (
    SELECT DISTINCT patient_num
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
        SELECT concept_cd
        FROM i2b2demodata.concept_dimension
        WHERE %s))
  AND (%s OR
    patient_num IN (
    SELECT patient_num
    FROM i2b2demodata.qt_patient_set_collection
    WHERE result_instance_id = %d)) "
  concept_condition <- paste("concept_path LIKE '", concepts, "%'", sep="")
  return(executeCRCQuery(queries.patientcount, concept_condition, patient_set < 0, patient_set))
} 

i2b2$crc$getPatientsCountWithObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\')) {
  queries.patientcount <- "SELECT count(DISTINCT patient_num) as counts
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE %s)
    AND (%s OR
      patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))"
  
  concept_condition <- paste("concept_path LIKE '", concepts, "%'", sep="")
  return(executeCRCQuery(queries.patientcount, concept_condition, patient_set < 0, patient_set))
} 

i2b2$crc$getVisitCountForPatientsWithObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\')) {
  queries.visitcount <- "SELECT visit_dimension.start_date, count(*) as counts
  FROM i2b2demodata.visit_dimension
  WHERE visit_dimension.patient_num IN
   (SELECT patient_num
     FROM (
       SELECT patient_num
       FROM i2b2demodata.observation_fact
       WHERE concept_cd IN (
         SELECT concept_cd
         FROM i2b2demodata.concept_dimension
         WHERE %s)
     GROUP BY patient_num) patients)
  AND (%s OR
    visit_dimension.patient_num IN (
    SELECT patient_num
    FROM i2b2demodata.qt_patient_set_collection
    WHERE result_instance_id = %d))
  GROUP BY visit_dimension.start_date
  ORDER BY visit_dimension.start_date"
  
  concept_condition <- paste("concept_path LIKE '", concepts, "%'", sep="")
  return(executeCRCQuery(queries.visitcount, concept_condition, patient_set < 0, patient_set))
}


i2b2$crc$getPatientsWithPlz <- function(patient_set=-1) {
  queries.patients <- "SELECT statecityzip_path, COUNT(*) as counts
    FROM i2b2demodata.patient_dimension
    WHERE (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))
    GROUP BY statecityzip_path"
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set))
}

i2b2$crc$getAllYearCosts <- function(patient_set_ids) {
  # returns summe_aller_kosten for each patient in patient_set for every year
  # to do: integrate to lib dataPrep.r/data access <- peter (y...? <- marc)

  query <- "SELECT patient_num, datum, summe_aller_kosten, arztkosten, zahnarztkosten, apothekenkosten, krankenhauskosten, hilfsmittel, heilmittel, dialysesachkosten, krankengeld
    FROM i2b2demodata.AVK_FDB_T_Leistungskosten 
    WHERE patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE %s)"

  patient_condition <- paste(paste("result_instance_id = ", patient_set_ids, sep=""), collapse=" OR ")

  result <- executeCRCQuery(query, patient_condition)
  return(result)
}
