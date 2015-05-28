i2b2$crc <- list()

source("i2b2.crc.config.r")

executeCRCQuery <- function(query, ..., silent=T) {
  return(executeQuery(i2b2$crc$db, query, ..., silent=silent))
}
#' 
#' Get the prefixes of all concepts that start with anything from the concepts list (all concepts by default)
#' @name getConcepts
#' @param concepts list of concepts to be compared to. Defaults to empty, meaning any prefix.
#' @param level Aggregates ICD codes, e.g. Level 3 = ICD:M54*, Level 1: ICD:M*
#' @return list of distinct concept_cd prefixes
#' @export
#' @examples
#' getConcepts()
#' getConcepts(c('\\ICD\\M'), 3)
i2b2$crc$getConcepts <- function(concepts=c(), level=3, silent=T) {
  queries.features <- "SELECT DISTINCT substring(concept_cd from 1 for %d) AS concept_cd_sub
  FROM i2b2demodata.concept_dimension
  WHERE (%s)"
  
  concept_condition <- paste(paste("concept_path LIKE '", escape(concepts), "%'", sep=""), collapse=" OR ")
  return(executeCRCQuery(queries.features, level + 4, concept_condition, silent=silent)$concept_cd_sub)
}

#'
#' Get all observations with specified properties
#' @name getObservations
#' @param interval specifies the time frame where the observations should come from
#' @param concepts specifies a subset where the observations should come from. Default is any concept.
#' @param level specifies ICD level to aggregate, e.g. Level 3 = ICD:M54*, Level 1: ICD:M*
#' @param patient_set id of the desired patient set, defaults to -1
#' @return list of observations with attributes patient_num, concept_cd_sub
#' @export
#' @examples
#' getObservations(list(start=i2b2DateToPOSIXlt("01/01/2009"), end=i2b2DateToPOSIXlt("01/01/2010")), 
#'   concepts=c("\\ICD\\", "\\ATC\\"), level=3, patient_set=-1)
#' getObservations(list(start=i2b2DateToPOSIXlt("01/01/2009"), end=i2b2DateToPOSIXlt("01/01/2010")), 
#'   concepts=c("\\ICD\\M00-M99\\M50-M54\\M54"), level=3, patient_set=-1)
i2b2$crc$getObservations <- function(interval, concepts=c(), level=3, patient_set=-1, silent=T) {
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
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, interval$start, interval$end, patient_set < 0, patient_set, silent=silent))
}

i2b2$crc$getObservationsDependingOnTreatment <- function(treatment.path, concepts=c(), intervalLength.Years = 3, level=3, patient_set=-1) {
  queries.observations <- "WITH p_date AS (SELECT patient_num, latest_tdate 
  FROM ( 
    SELECT patient_num, MIN(start_date) AS latest_tdate 
    FROM i2b2demodata.observation_fact 
    WHERE concept_cd IN ( 
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE concept_path LIKE '%s%%')
    AND (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))
    GROUP BY patient_num) tdates)
  SELECT patient_num, concept_cd_sub, count(*) AS counts
    FROM (
      SELECT obs.patient_num, substring(concept_cd from 1 for %d) AS concept_cd_sub
      FROM (
    SELECT patient_num, concept_cd, start_date
    FROM i2b2demodata.observation_fact
    WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE (%s))
    AND (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))) obs
      INNER JOIN p_date ON obs.patient_num = p_date.patient_num
      AND (start_date >= p_date.latest_tdate - interval '%d years' AND start_date <= p_date.latest_tdate)) observations
    GROUP BY patient_num, concept_cd_sub"

#  treatment.path <<- paste0(treatment.path, "%%") 
  concept_condition <<- paste(paste("concept_path LIKE '", escape(concepts), "%'", sep=""), collapse=" OR ")
  return(executeCRCQuery(queries.observations, escape(treatment.path),
    patient_set < 0, patient_set, level+4, concept_condition, patient_set < 0, patient_set, intervalLength.Years))
}

#'
#' Get all observations for a specified concept with specified properties
#' @name GetObservationsForConcept
#' @param interval specifies the time frame where the observations should come from
#' @param concept.path specifies the path for the concept where the observations should come from.
#' @param patient_set id of the desired patient set, defaults to -1
#' @return list of observations with attributes patient_num, concept_cd_sub, counts
#' @export
#' @examples
#' getObservationsForConcept(list(start=i2b2DateToPOSIXlt("01/01/2009"), end=i2b2DateToPOSIXlt("01/01/2010")), 
#'   concept.path="\\ICD\\M00-M99\\M50-M54\\M54\\", patient_set=-1)
i2b2$crc$getObservationsForConcept <- function(interval, concept.path, patient_set=-1, silent=T) {
  queries.observations <- "SELECT patient_num, count(*) AS counts
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
  return(executeCRCQuery(queries.observations, table, column, operator, parameter, interval$start, interval$end, patient_set < 0, patient_set, silent=silent))
}
#'
#' Get all patients of a patient set
#' @name getPatients
#' @param patient_set Id of the desired patient set 
#' @return list of patients with patient_num, sex_cd, birth_date 
#' @export
#' @examples
#' getPatients(patient_set=-1)
i2b2$crc$getPatients <- function(patient_set=-1, silent=T) {
  queries.patients <- "SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))"
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set, silent=silent))
}

i2b2$crc$getPatientsForConcept <- function(patient_set=-1, concept.path) {
  queries.patients <- "SELECT DISTINCT patient_num
  FROM i2b2demodata.observation_fact
  WHERE concept_cd IN (
      SELECT concept_cd
      FROM i2b2demodata.concept_dimension
      WHERE concept_path LIKE '%s%%')
  AND (TRUE = %s
  OR patient_num IN (
    SELECT patient_num
    FROM i2b2demodata.qt_patient_set_collection
    WHERE result_instance_id = %d))"
  
  return(executeCRCQuery(queries.patients, escape(concept.path), patient_set < 0, patient_set)$patient_num)
}


#'
#' Get the description of a patient set
#' @name GetPatientSetDescription
#' @param patient_set Id of the desired patient set 
#' @return string with description of the patient set
#' @export
#' @examples
#' getPatientSetDescription(patient_set=42)
i2b2$crc$getPatientSetDescription <- function(patient_set, silent=T) {
  queries.patient_set <- "SELECT description
    FROM i2b2demodata.qt_query_result_instance
    WHERE result_instance_id = %d"
  
  return(executeCRCQuery(queries.patient_set, patient_set, silent=silent)$description)
}

#'
#' Get patients of a patient set with a limit to speed up development
#' @name getPatientsWithLimit
#' @param patient_set Id of the desired patient set 
#' @param limit limit of patients to be returned
#' @return list of patients with patient_num, sex_cd, birth_date 
#' @export
#' @examples
#' getPatientsWithLimit(patient_set=-1, limit=100)
i2b2$crc$getPatientsWithLimit <- function(patient_set=-1, limit=100, silent=T) {
  queries.patients <- paste("SELECT patient_num, sex_cd, birth_date
    FROM i2b2demodata.patient_dimension
    WHERE %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d)
    LIMIT ", limit)
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set, silent=silent))
}

#' 
#' Get observations with a limit to speed up development
#' @name getObservationsWithLimit
#' @param interval specifies start and end of the interval in a list
#' @param concepts list of concepts for the observations
#' @param level specifies the aggregation level of concepts
#' @param patients_limit limit of observations to be returned
#' @return list of observations with patient_num, concept_cd>sub, counts
#' @export
#' @examples
#' getObservationsWithLimit(list(start=i2b2DateToPOSIXlt("01/01/2009"), end=i2b2DateToPOSIXlt("01/01/2010")), 
#'   concepts=c("ICD:", "ATC:"), level=3, patients_limit=1000)
i2b2$crc$getObservationsWithLimit <- function(interval, concepts=c(), level=3, patients_limit, silent=T) {
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
  return(executeCRCQuery(queries.observations, level + 4, concept_condition, patients_limit, silent=silent))
}

i2b2$crc$getVisitCountForPatientsWithoutObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\'), silent=T) {
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
  return(executeCRCQuery(queries.visitcount, concept_condition, patient_set < 0, patient_set, silent=silent))
}

i2b2$crc$getPatientsCountWithoutObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\'), silent=T) {
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
  return(executeCRCQuery(queries.patientcount, concept_condition, patient_set < 0, patient_set, silent=silent))
} 

i2b2$crc$getPatientsCountWithObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\'), silent=T) {
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
  return(executeCRCQuery(queries.patientcount, concept_condition, patient_set < 0, patient_set, silent=silent))
} 

i2b2$crc$getVisitCountForPatientsWithObservation <- function(patient_set=-1, concepts=c('\\\\ICD\\\\M00-M99\\\\M91-M94\\\\M94\\\\'), silent=T) {
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
  return(executeCRCQuery(queries.visitcount, concept_condition, patient_set < 0, patient_set, silent=silent))
}


i2b2$crc$getPatientsWithPlz <- function(patient_set=-1, silent=T) {
  queries.patients <- "SELECT statecityzip_path, COUNT(*) as counts
    FROM i2b2demodata.patient_dimension
    WHERE (TRUE = %s
    OR patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE result_instance_id = %d))
    GROUP BY statecityzip_path"
  
  return(executeCRCQuery(queries.patients, patient_set < 0, patient_set, silent=silent))
}

i2b2$crc$getAllYearCosts <- function(patient_set_ids, silent=T) {
  # returns summe_aller_kosten for each patient in patient_set for every year
  # to do: integrate to lib dataPrep.r/data access <- peter (y...? <- marc)

  query <- "SELECT patient_num, datum, summe_aller_kosten, arztkosten, zahnarztkosten, apothekenkosten, krankenhauskosten, hilfsmittel, heilmittel, dialysesachkosten, krankengeld
    FROM i2b2demodata.AVK_FDB_T_Leistungskosten 
    WHERE patient_num IN (
      SELECT patient_num
      FROM i2b2demodata.qt_patient_set_collection
      WHERE %s)"

  patient_condition <- paste(paste("result_instance_id = ", patient_set_ids, sep=""), collapse=" OR ")

  result <- executeCRCQuery(query, patient_condition, silent=silent)
  return(result)
}
