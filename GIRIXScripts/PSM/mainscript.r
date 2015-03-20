# required packages needed, must be installed first
require(Matrix)
require(Matching)

source("PSM/logic.r")
source("lib/i2b2.r")

if(!exists('girix.input')) {
  source("PSM/girix_input.r")
}

# to do: to be set in configuration tab
girix.input['Feature level'] <- 3

# for debugging: limits database queries to decrease waiting times
patients.limit <- 10000
interval.limit <- list(start=as.Date("2008-01-01"), end=as.Date("2009-01-01"))

# input preparation to be done by GIRI
features.filter <- c("ATC:", "ICD:")
features.level <- strtoi(girix.input['Feature level'])
features <- i2b2$crc$getConcepts(concepts=features.filter, level=features.level) # to adapt feature set


# get feature set including all ATC/ICDs out of database
print("getting featureMatrix")
featureMatrix <- generateFeatureMatrix(interval=interval.limit, patients_limit= patients.limit, level=features.level, features=features, filter=features.filter)

print("calculating probabilities")
patients.probs <- ProbabilitiesOfLogRegFitting(featureMatrix, girix.input['Evaluated treatment'])

to.match <- Scores.TreatmentsForMonitoredConcept(all.patients = featureMatrix, patients.probabilities = patients.probs, 
                                                 concept=girix.input['Observed patient concept'])

print("matching")
matched <- Match(Tr=to.match[,"Treatment"], X=to.match[,"Probability"], exact=FALSE, ties=F, version="fast")

print("outputting")
output <- cbind(rownames(to.match[matched$index.control,]), to.match[matched$index.control,"Probability"], rownames(to.match[matched$index.treated,]), to.match[matched$index.treated, "Probability"])
colnames(output) <- c("Control group patient number", "Score", "Treatment group patient number", "Score")
girix.output[["Matched patients"]] <- output