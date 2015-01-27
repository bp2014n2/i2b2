# Abbrevations
childConcPath <- report.input["Child concept"]
numObs <- nrow(report.observations[[1]])

# Filter observations of child concepts and count them
filteredObs <- report.observations[[1]][(substr(report.observations[[1]]$concept_path, 1, nchar(childConcPath)) == childConcPath),]
numChilds <- nrow(filteredObs)

# Set output
report.output[["Top level concept"]] <- report.concept.names[1]
report.output[["Child concept"]] <- childConcPath
report.output[["Relative frequency of observations of child concept"]] <- numChilds / numObs



