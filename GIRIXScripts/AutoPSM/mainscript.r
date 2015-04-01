# required packages needed, must be installed first
require(Matrix)
require(Matching)

source("AutoPSM/logic.r")
source("lib/i2b2.r")

if(!exists('girix.input')) {
  source("AutoPSM/girix_input.r")
}

# to do: to be set in configuration tab
girix.input['Feature level'] <- 3

# for debugging: limits database queries to decrease waiting times
patients.limit <- 10000
#interval.limit <- list(start=as.Date("2008-01-01"), end=as.Date("2009-01-01"))

# input preparation to be done by GIRI
features.filter <- c("ATC:", "ICD:")
features.level <- strtoi(girix.input['Feature level'])
features <- i2b2$crc$getConcepts(concepts=features.filter, level=features.level) # to adapt feature set

# get feature set including all ATC/ICDs out of database
print("getting featureMatrix")
featureMatrix <- generateFeatureMatrix(patients_limit= patients.limit, level=features.level, features=features, filter=features.filter)

print("calculating probabilities")
patients.probs <- ProbabilitiesOfLogRegFitting(featureMatrix, girix.input['Evaluated treatment'])

to.match <- Scores.TreatmentsForMonitoredConcept(all.patients = featureMatrix, patients.probabilities = patients.probs, 
                                                 concept=girix.input['Observed patient concept'])

print("matching")
matched <- Match(Tr=to.match[,"Treatment"], X=to.match[,"Probability"], M=1, exact=TRUE, ties=TRUE, version="fast")

print("outputting")
output <- cbind(rownames(to.match[matched$index.treated,]), to.match[matched$index.treated,"Probability"], rownames(to.match[matched$index.control,]), to.match[matched$index.control, "Probability"])
colnames(output) <- c("Treatment group patient number", "Score", "Control group patient number", "Score")
rownames(output) <- c()

matching.description <- paste0("Matching on patients that have diagnose(s) <b>", i2b2ConceptToHuman(girix.input['Observed patient concept']), 
                              "</b>. <nl>Evaluated treatment is <b>", i2b2ConceptToHuman(girix.input["Evaluated treatment"]), "</b>.")

girix.output[["Matched patients"]] <- output[1:20,]
girix.output[["Matching description"]] <- matching.description