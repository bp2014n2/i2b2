require(Matrix)
require(Matching)

source("../lib/i2b2.r", chdir=TRUE)
source("../lib/dataPrep.r", chdir=TRUE)
source("logic.r")

if(!exists('girix.input')) {
  source("girix_input.r")
}

# girix input processing
patientset.t.id <- strtoi(girix.input['Treatment group'])
patientset.c.id <- strtoi(girix.input['Control group'])
treatmentDate <- i2b2DateToPOSIXlt(girix.input['Treatment date'])

# i2b2 date format (MM/DD/YYYY)
interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=treatmentDate)

print("getting featureMatrices")
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval)
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval)

featureMatrix <- rbind2(featureMatrix.t, featureMatrix.c)

print("calculating probabilities")
target.vector <- c(rep(1, each=nrow(featureMatrix.t)),rep(0, each=nrow(featureMatrix.c)))
probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector=target.vector)

print("matching")
matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")

print("getting and calculating costs")
treatmentYear <- as.numeric(format(treatmentDate, "%Y"))
previousYear <- treatmentYear -1
print("preparing pnums") #debug
pnums.treated <- rownames(featureMatrix)[matched$index.treated]
pnums.control <- rownames(featureMatrix)[matched$index.control]  # contains together with pnums.treated the matching information(order matters)
print("quering costs") #debug
costs.tY <- GetOneYearCosts(c(pnums.treated, pnums.control), treatmentYear)
costs.pY <- GetOneYearCosts(c(pnums.treated, pnums.control), previousYear)

print("outputting")
output <- matrix()
output <- cbind(pnums.treated, probabilities[matched$index.treated, "probabilities"], costs.pY[pnums.treated,"sum"], costs.tY[pnums.treated,"sum"],
				pnums.control, probabilities[matched$index.control, "probabilities"], costs.pY[pnums.control,"sum"], costs.tY[pnums.control,"sum"])

colnames(output) <- c("Treatment group p_num", "Score", "Costs year before", "Costs treatment year", 
					  "Control group p_num", "Score", "Costs year before", "Costs treatment year")
rownames(output) <- c()

print(output[1:2,])

girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "Verbose labels of columns: patient number (treatment group), Propensity Score, 
										  Overall costs of patient in the year before treatment, Overall costs of patient in the year of treatment.
										  Simulatenously for the following four columns for patients of control group"