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
treatmentDate <- eval(parse(text=girix.input['Treatment Quarter']))
treatmentYear <- treatmentDate["year"]
treatmentQuarter <- treatmentDate["quarter"]
features <- eval(parse(text=girix.input['Feature Selection']))
splitBy <- eval(parse(text=girix.input['Exact matching']))
level <- strtoi(girix.input['Feature level'])
addFeatures <- c(girix.input['Additional feature 1'],
	girix.input['Additional feature 2'],
	girix.input['Additional feature 3'],
	girix.input['Additional feature 4'],
	girix.input['Additional feature 5'])

print(treatmentDate)
print(treatmentYear)
print(treatmentQuarter)

# i2b2 date format (MM/DD/YYYY)
interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=as.Date(getDate(treatmentYear,treatmentQuarter)))

print("getting featureMatrices")
filter <- c()
if(features["ICD"] == TRUE) {
	filter <- append(filter, 'ICD:')
}
if(features["ATC"] == TRUE) {
	filter <- append(filter, 'ATC:')
}
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval, filter=filter, level=level)
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval, filter=filter, level=level)

featureMatrix <- cbind(featureMatrix.t, featureMatrix.c)

print("calculating probabilities")
target.vector <- c(rep(1, each=nrow(featureMatrix.t)),rep(0, each=nrow(featureMatrix.c)))
probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector=target.vector)

print("matching")
matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")

print("preparing pnums") #debug
pnums.treated <- rownames(featureMatrix)[matched$index.treated]
pnums.control <- rownames(featureMatrix)[matched$index.control]  # contains together with pnums.treated the matching information(order matters)

print("quering costs") #debug
costs <- i2b2$crc$getAllYearCosts(c(patientset.t.id, patientset.c.id))
treatmentDate <- getDate(treatmentYear, treatmentQuarter)
yearBeforeTreatmentDate <- getDate(as.integer(treatmentYear) - 1, treatmentQuarter)
yearAfterTreatmentDate <- getDate(as.integer(treatmentYear) + 1, treatmentQuarter)
costs.pY <- costs[yearBeforeTreatmentDate <= costs[, "datum"] & costs[, "datum"] < treatmentDate,]
costs.pY <- aggregate(summe_aller_kosten ~ patient_num, data = costs.pY, sum)
row.names(costs.pY) <- costs.pY[,"patient_num"]
costs.tY <- costs[treatmentDate <= costs[, "datum"] & costs[, "datum"] < yearAfterTreatmentDate,]
costs.tY <- aggregate(summe_aller_kosten ~ patient_num, data = costs.tY, sum)
row.names(costs.tY) <- costs.tY[,"patient_num"]
costs.treated <- costs[costs[,"patient_num"] %in% pnums.treated,]
costs.control <- costs[costs[,"patient_num"] %in% pnums.control,]

costsPerYear.treated <- aggregate(summe_aller_kosten ~ datum, data=costs.treated, mean)
costsPerYear.control <- aggregate(summe_aller_kosten ~ datum, data=costs.control, mean)
costsPerYear.treated[,1] <- as.Date(costsPerYear.treated[,1])
costsPerYear.control[,1] <- as.Date(costsPerYear.control[,1])

plot(costsPerYear.treated,type="l",xlab="Quartal/Jahr",ylab="Kosten",bty="n")
lines(costsPerYear.control,type="l",col=accentColor[2])
lineHeight <- max(max(costsPerYear.treated[,"summe_aller_kosten"]),max(costsPerYear.control[,"summe_aller_kosten"]))+20
arrows(as.Date(treatmentDate),-10,as.Date(treatmentDate),lineHeight,lwd=1.25,length=0,xpd=TRUE,col=darkGray)
text(as.Date(treatmentDate),lineHeight+10,"Treatment Date",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=darkGray)
text(max(costsPerYear.treated[,"datum"]),lineHeight-10,"Treatment Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=baseColor)
text(max(costsPerYear.treated[,"datum"]),lineHeight-20,"Control Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=accentColor[2])

print("outputting")
options(scipen=999)
treatmentMean <- round(mean(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
treatmentMedian <- round(median(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
controlMean <- round(mean(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
controlMedian <- round(median(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
scoreDiffMean <- round(mean(abs(probabilities[matched$index.treated,"probabilities"] - probabilities[matched$index.control,"probabilities"])))

validationParams <- c("mean of treatment scores"=treatmentMean,
	"median of treatment scores"=treatmentMedian,
	"mean of control scores"=controlMean,
	"median of control scores"=controlMedian,
	"mean ofsosour score difference"=scoreDiffMean)
matchedPatients <- matrix()
matchedPatients <- cbind(pnums.treated, round(probabilities[matched$index.treated, "probabilities"], 4), round(costs.pY[pnums.treated,"summe_aller_kosten"], 2), round(costs.tY[pnums.treated,"summe_aller_kosten"], 2),
				pnums.control, round(probabilities[matched$index.control, "probabilities"], 4), round(costs.pY[pnums.control,"summe_aller_kosten"], 2), round(costs.tY[pnums.control,"summe_aller_kosten"], 2))

colnames(matchedPatients) <- c("Treatment group p_num", "Score", "Costs year before", "Costs treatment year", 
					  "Control group p_num", "Score", "Costs year before", "Costs treatment year")
rownames(matchedPatients) <- c()

print(matchedPatients[1:2,])
print(validationParams)

girix.output[["Matched patients"]] <- matchedPatients
girix.output[["Matching description"]] <- "Verbose labels of columns: patient number (treatment group), Propensity Score, 
										  Overall costs of patient in the year before treatment, Overall costs of patient in the year of treatment.
										  Simulatenously for the following four columns for patients of control group"
girix.output[["Validation Parameters"]] <- validationParams
girix.output[["Costs per year"]] <- ""
