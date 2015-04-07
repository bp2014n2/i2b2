require(Matrix)
require(Matching)

source("../lib/i2b2.r", chdir=TRUE)
source("../lib/dataPrep.r", chdir=TRUE)
source("logic.r")

if(!exists('girix.input')) {
  source("girix_input.r")
}

patientset.t.id <- girix.input['Treatment group']
patientset.c.id <- girix.input['Control group']

# i2b2 date format (MM/DD/YYYY)
#interval <- list(start='01/01/2000', end='12/31/2015') 
interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=i2b2DateToPOSIXlt('12/31/2015'))

print("getting featureMatrices")
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval)
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval)

featureMatrix <- rbind2(featureMatrix.t, featureMatrix.c)

print("calculating probabilities")
target.vector <- c(rep(1, each=nrow(featureMatrix.t)),rep(0, each=nrow(featureMatrix.c)))
probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector)

print("matching")
matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")

print("outputting")
output <- cbind(rownames(to.match[matched$index.treated,]), to.match[matched$index.treated,"Probability"], rownames(to.match[matched$index.control,]), to.match[matched$index.control, "Probability"])
colnames(output) <- c("Treatment group patient number", "Score", "Control group patient number", "Score")
rownames(output) <- c()

girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "No dummy matching anymore ;)"