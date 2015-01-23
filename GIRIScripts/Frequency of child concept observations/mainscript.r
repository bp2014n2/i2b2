# Abbrevations
childConcPath <- GIRI.input["Child concept"]
numObs <- nrow(GIRI.observations[[1]])

# Filter observations of child concepts and count them
filteredObs <- GIRI.observations[[1]][(substr(GIRI.observations[[1]]$concept_path, 1, nchar(childConcPath)) == childConcPath),]
numChilds <- nrow(filteredObs)

# Set output
GIRI.output[["Top level concept"]] <- GIRI.concept.names[1]
GIRI.output[["Child concept"]] <- childConcPath
GIRI.output[["Relative frequency of observations of child concept"]] <- numChilds / numObs



