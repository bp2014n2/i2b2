require(Matrix)
require(Matching)
q
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

print(girix.input['Treatment date'])

# i2b2 date format (MM/DD/YYYY)
#interval <- list(start='01/01/2000', end='12/31/2015') 
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
cost.query.result <- GetYearCosts(rownames(featureMatrix))
treatmentYear <- as.numeric(format(treatmentDate, "%Y"))
previousYear <- treatmentYear -1

costs.t <- matrix()
j <- 1
for (i in rownames(featureMatrix[matched$index.treated,])) {
	# first column: costs of year before treatment
	# second column: costs of year of treatment
	#third column: patientnum
	costs.t[j, 1] <- cost.query.result[intersect(which((cost.query.result["patient_num"]==i)), 
												which((cost.query.result["datum_year"]==(previousYear)))),3]
	costs.t[j, 2] <- cost.query.result[intersect(which((cost.query.result["patient_num"]==i)), 
												which((cost.query.result["datum_year"]==(treatmentYear)))),3]
	#costs.t[j, 2] <- which((cost.query.result["patient_num"]==i) & (cost.query.result["datum_year"]==treatmentYear))
	costs.t[j, 3] <- i
	j <- j + 1
}



print("outputting")
output <- cbind(rownames(featureMatrix[matched$index.treated,]), probabilities[matched$index.treated,1], 
				costs.t[,1:2],
				rownames(featureMatrix[matched$index.control,]), probabilities[matched$index.control,1],
				costs.c[,1:2])
colnames(output) <- c("Treatment group patient number", "Score", "Control group patient number", "Score")
rownames(output) <- c()

girix.output[["Matched patients"]] <- output
girix.output[["Matching description"]] <- "No dummy matching anymore ;)"