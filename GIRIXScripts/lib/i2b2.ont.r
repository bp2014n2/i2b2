i2b2$ont <- list()

source("i2b2.ont.config.r")

executeONTQuery <- function(query, ...) {
  return(executeQuery(i2b2$ont$db, query, ...))
}

i2b2$ont$getConceptName <- function(concept.path) {
  query <- "SELECT c_name
  FROM i2b2metadata.eva_meta
  WHERE c_fullname LIKE '%s'"
  return(executeONTQuery(query, escape(concept.path)))
}

i2b2$ont$getConceptNameForBasecode <- function(concept.cd) {
  query <- "SELECT c_name
  FROM i2b2metadata.eva_meta
  WHERE c_basecode LIKE '%s'"
  return(executeONTQuery(query, concept.cd))
}

i2b2$ont$getTableAndColumn <- function(concept.path) {
  query <- "SELECT c_tablename, c_columnname, c_columndatatype, c_operator
  FROM i2b2metadata.eva_meta
  WHERE c_fullname LIKE '%s'"
  return(executeONTQuery(query, escape(concept.path)))
}