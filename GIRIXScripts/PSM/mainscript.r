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
treatmentYear <- girix.input['Treatment year']
treatmentQuarter <- girix.input['Treatment quarter']
useICDs <- girix.input['useICDs']
useATCs <- girix.input['useATCs']
level <- strtoi(girix.input['Feature level'])

# i2b2 date format (MM/DD/YYYY)
interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=as.Date(getDate(treatmentYear,treatmentQuarter)))

print("getting featureMatrices")
filter <- c()
if(useICDs == '1') {
	filter <- append(filter, 'ICD:')
}
if(useATCs == '1') {
	filter <- append(filter, 'ATC:')
}
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval, filter=filter)
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval, filter=filter)

featureMatrix <- rbind2(featureMatrix.t, featureMatrix.c)

print("calculating probabilities")
target.vector <- c(rep(1, each=nrow(featureMatrix.t)),rep(0, each=nrow(featureMatrix.c)))
probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector=target.vector)

treatmentMean <- mean(probabilities[,2])
treatmentMedian <- median(probabilities[,2])
controlMean <- mean(probabilities[,1])
controlMedian <- median(probabilities[,1])

validationParams <- c(treatmentMean=treatmentMean,treatmentMedian=treatmentMedian,controlMean=controlMean,controlMedian=controlMedian)

print("matching")
matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")

print("preparing pnums") #debug
pnums.treated <- rownames(featureMatrix)[matched$index.treated]
pnums.control <- rownames(featureMatrix)[matched$index.control]  # contains together with pnums.treated the matching information(order matters)

print("quering costs") #debug
costs <- GetAllYearCosts(c(pnums.treated, pnums.control))
treatmentDate <- getDate(treatmentYear, treatmentQuarter)
yearBeforeTreatmentDate <- getDate(as.integer(treatmentYear) - 1, treatmentQuarter)
yearAfterTreatmentDate <- getDate(as.integer(treatmentYear) + 1, treatmentQuarter)
costs.pY <- costs[yearBeforeTreatmentDate <= costs[, "datum"] & costs[, "datum"] < treatmentDate]
costs.tY <- costs[treatmentDate <= costs[, "datum"] & costs[, "datum"] < yearAfterTreatmentDate]

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
girix.output[["Validation Parameters"]] <- validationParams
girix.output[["Costs per year"]] <- ""