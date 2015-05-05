require(Matrix)
require(Matching)

if(!exists('girix.input')) {
  setwd('/home/ubuntu/i2b2/GIRIXScripts/PSM')
  source("girix_input.r")
}

source("../lib/i2b2.r", chdir=TRUE)
source("../lib/dataPrep.r", chdir=TRUE)
source("logic.r")

# girix input processing
patientset.t.id <- strtoi(girix.input['Treatment group'])
patientset.c.id <- strtoi(girix.input['Control group'])
treatmentDate <- i2b2DateToPOSIXlt(girix.input['Treatment date'])

# i2b2 date format (MM/DD/YYYY)
interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=treatmentDate)

print("getting featureMatrices")
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval)
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval)
print("Hallo")
featureMatrix <- rbind2(featureMatrix.t, featureMatrix.c)

print("calculating probabilities")
target.vector <- c(rep(1, each=nrow(featureMatrix.t)),rep(0, each=nrow(featureMatrix.c)))
probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector=target.vector)

print("matching")
matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")

print("getting and calculating costs")
treatmentYear <- as.numeric(format(treatmentDate, "%Y"))
previousYear <- treatmentYear -1
pnums.treated <- rownames(featureMatrix)[matched$index.treated]
pnums.control <- rownames(featureMatrix)[matched$index.control]  # contains together with pnums.treated the matching information(order matters)
costs.tY <- GetOneYearCosts(c(pnums.treated, pnums.control), treatmentYear)
costs.pY <- GetOneYearCosts(c(pnums.treated, pnums.control), previousYear)

print("outputting")
options(scipen=999)
output <- matrix()
output <- cbind(pnums.treated, round(probabilities[matched$index.treated, "probabilities"], 4), round(costs.pY[pnums.treated,"sum"], 2), round(costs.tY[pnums.treated,"sum"], 2),
				pnums.control, round(probabilities[matched$index.control, "probabilities"], 4), round(costs.pY[pnums.control,"sum"], 2), round(costs.tY[pnums.control,"sum"], 2))

colnames(output) <- c("Treatment group p_num", "Score", "Costs year before", "Costs treatment year", 
					  "Control group p_num", "Score", "Costs year before", "Costs treatment year")
rownames(output) <- c()

girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "Verbose labels of columns: patient number (treatment group), Propensity Score, 
										  Overall costs of patient in the year before treatment, Overall costs of patient in the year of treatment.
										  Simulatenously for the following four columns for patients of control group"
