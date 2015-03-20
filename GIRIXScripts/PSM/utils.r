i2b2ConceptToHuman <- function(i2b2concept) {
# to do: to implement concept ranges: return list if path is a node (query)/ range

# transforms e.g. "\\ICD\\M00-M99\\M50-M54\\M54\\" to "ICD:M54"
  if (substr(i2b2concept, start=2, stop=4) == "ICD" ) {
    code <- sub("[\\]$","", i2b2concept)
    code <- sub("^.*[\\]", "", code)
    result <- paste("ICD:", code, sep="")
  }
  
  if (substr(i2b2concept, start=2, stop=4) == "ATC" ) {
    result <- sub("^[\\]ATC[\\]", "", i2b2concept)
    result <- gsub("[\\]","",result)
    result <- paste("ATC:", result, sep="")
  }
  
  return(result)
}