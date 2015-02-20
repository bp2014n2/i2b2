require(RPostgreSQL)

executeQuery <- function(con, query, ...) {
  
  final_query <- sprintf(query, ...)
  print(final_query)
  return(dbGetQuery(con, final_query))
  
}

initializeCRCConnection <- function() {
  drv <- dbDriver("PostgreSQL")
  return(dbConnect(drv, dbname="i2b2", host="localhost", user="i2b2demodata", password="demouser", port="5432"))
}

destroyCRCConnection <- function(con) {
  
  dbDisconnect(con)
  
}

queries.observations <- "SELECT patient_num, concept_cd, count(*) AS count
FROM (
  SELECT patient_num, substring(concept_cd from '(%s.{3})') AS concept_cd
  FROM i2b2demodata.observation_fact
  WHERE concept_cd IN (
    SELECT concept_cd
    FROM i2b2demodata.concept_dimension
    WHERE concept_cd SIMILAR TO '%s%%')
  AND (start_date >= '%sT00:00:00' AND start_date <= '%sT00:00:00')) observations
GROUP BY patient_num, concept_cd"

queries.patients <- "SELECT DISTINCT patient_num
FROM i2b2demodata.patient_dimension"

queries.features <- "SELECT DISTINCT substring(concept_cd from '(%s.{3})') AS concept_cd
FROM i2b2demodata.concept_dimension
WHERE concept_cd SIMILAR TO '%s%%'"

queries.concept_cd <- "SELECT concept_cd
FROM i2b2demodata.concept_dimension
WHERE concept_path LIKE '%s'"