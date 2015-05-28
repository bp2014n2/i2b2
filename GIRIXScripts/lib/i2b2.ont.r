i2b2$ont <- list()

source("i2b2.ont.config.r")

executeONTQuery <- function(query, ..., silent=T) {
  return(executeQuery(i2b2$ont$db, query, ..., silent=silent))
}

i2b2$ont$getConceptName <- function(concept.path, silent=T) {
  query <- "SELECT c_name
  FROM i2b2metadata.eva_meta
  WHERE c_fullname LIKE '%s'"
  return(executeONTQuery(query, escape(concept.path), silent=silent))
}

i2b2$ont$getConceptNameForBasecode <- function(concept.cd, silent=T) {
  query <- "SELECT c_name
  FROM i2b2metadata.eva_meta
  WHERE c_basecode LIKE '%s'"
  return(executeONTQuery(query, concept.cd, silent=silent))
}

i2b2$ont$getTableAndColumn <- function(concept.path, silent=T) {
  query <- "SELECT c_tablename, c_columnname, c_columndatatype, c_operator
  FROM i2b2metadata.eva_meta
  WHERE c_fullname LIKE '%s'"
  return(executeONTQuery(query, escape(concept.path), silent=silent))
}
