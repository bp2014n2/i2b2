require(Matrix)
require(Matching)

if(!exists('girix.input')) {
  source("/home/ubuntu/i2b2/GIRIXScripts/lib/girix.r")
  source("PSM/girix_input.r")
}

source("../lib/i2b2.r", chdir=TRUE)
source("../lib/dataPrep.r", chdir=TRUE)
source("logic.r")

time.query <- 0
timings <- c()
stats <- c()
time.start <<- proc.time()

timingTag <- function(name) {
  time.end <<- proc.time()
  timings[name] <<- sum(c(time.end-time.start)[3])
  time.start <<- proc.time()
}

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

timingTag("Input Processing")

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
timingTag("-")
featureMatrix.t <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.t.id, interval=interval, filter=filter, level=level)
timingTag("featureMatrix.t")
featureMatrix.c <- DataPrep.generateFeatureMatrixFromPatientSet(patient_set=patientset.c.id, interval=interval, filter=filter, level=level)
timingTag("featureMatrix.c")

splitByGender <- function(features) {
  gender <- list()
  gender[[1]] <- list()
  gender[[2]] <- list()
  gender[[1]]$target <- features$target[features$target[,"sex"] == 1,]
  gender[[1]]$control <- features$control[features$control[,"sex"] == 1,]
  gender[[2]]$target <- features$target[features$target[,"sex"] != 1,]
  gender[[2]]$control <- features$control[features$control[,"sex"] != 1,]
  return(gender)
}

splitByAge <- function(features) {
  gender <- list()
  gender[[1]] <- list()
  gender[[1]]$target <- features$target[features$target[,"age"] < 30,]
  gender[[1]]$control <- features$control[features$control[,"age"] < 30,]
  gender[[2]] <- list()
  gender[[2]]$target <- features$target[features$target[,"age"] >= 30 & features$target[,"age"] < 40,]
  gender[[2]]$control <- features$control[features$control[,"age"] >= 30 & features$control[,"age"] < 40,]
  gender[[3]] <- list()
  gender[[3]]$target <- features$target[features$target[,"age"] >= 40 & features$target[,"age"] < 50,]
  gender[[3]]$control <- features$control[features$control[,"age"] >= 40 & features$control[,"age"] < 50,]
  gender[[4]] <- list()
  gender[[4]]$target <- features$target[features$target[,"age"] >= 50 & features$target[,"age"] < 60,]
  gender[[4]]$control <- features$control[features$control[,"age"] >= 50 & features$control[,"age"] < 60,]
  gender[[5]] <- list()
  gender[[5]]$target <- features$target[features$target[,"age"] >= 60 & features$target[,"age"] < 70,]
  gender[[5]]$control <- features$control[features$control[,"age"] >= 60 & features$control[,"age"] < 70,]
  gender[[6]] <- list()
  gender[[6]]$target <- features$target[features$target[,"age"] >= 70,]
  gender[[6]]$control <- features$control[features$control[,"age"] >= 70,]
  for(g in gender) {
    if(nrow(g$target) == 0 | nrow(g$control) == 0) {
      g <- NULL
    }
  }
  print(length(gender))
  return(gender)
}

psm <- function(features.target, features.control, age=FALSE, sex=FALSE) {
  splitted <- list()
  splitted[[1]] <- list()
  splitted[[1]]$target <- features.target
  splitted[[1]]$control <- features.control
  if (sex) {
    gender <- list()
    for(features in splitted) {
      gender <- c(gender, splitByGender(features))
    }
    splitted <- gender
  }
  if (age) {    
    age <- list()
    for(features in splitted) {  
      age <- c(age, splitByAge(features))
    }
    splitted <- age
  }
  result <- NULL
  for(features in splitted) {
    result.tmp <- primitivePSM(features)
    if(is.null(result)) {
      result <- list()
      result$matched <- list()
      result$matched$index.control <- result.tmp$matched$index.control
      result$matched$index.treated <- result.tmp$matched$index.treated
      result$probabilities <- result.tmp$probabilities
      result$featureMatrix <- result.tmp$featureMatrix
    } else {
      result$probabilities <- rbind2(result$probabilities, result.tmp$probabilities)
      result$matched$index.control <- c(result$matched$index.control, result.tmp$matched$index.control)
      result$matched$index.treated <- c(result$matched$index.treated, result.tmp$matched$index.treated)
      result$featureMatrix <- rbind2(result$featureMatrix, result.tmp$featureMatrix)
    }
  }
  return(result)
}

primitivePSM <- function(features) {
  features.target <- features$target
  features.control <- features$control
  print("calculating probabilities")
  target.vector <- c(rep(1, each=nrow(features.target)),rep(0, each=nrow(features.control)))
  featureMatrix <- rbind2(features.target,features.control)
  probabilities <- ProbabilitiesOfLogRegFittingWithTargetVector(featureMatrix=featureMatrix, target.vector=target.vector)
  timingTag("log reg")
  matched <- Match(Tr=probabilities[,2], X=probabilities[,1], M=1, exact=TRUE, ties=TRUE, version="fast")
  timingTag("matching")
  result <- list()
  result$probabilities <- probabilities
  result$matched <- matched
  result$featureMatrix <- featureMatrix
  return(result)
}

result <- psm(features.target=featureMatrix.t,features.control=featureMatrix.c, sex=splitBy["Gender"], age=splitBy["Age"])

probabilities <- result$probabilities

matched <- result$matched
featureMatrix <- result$featureMatrix

timingTag("Matching")

print("preparing pnums") #debug
pnums.treated <- rownames(featureMatrix)[matched$index.treated]
pnums.control <- rownames(featureMatrix)[matched$index.control]  # contains together with pnums.treated the matching information(order matters)

stats["pnums.treated"] <- length(pnums.treated)
stats["pnums.control"] <- length(pnums.control)


print("quering costs") #debug
costs <- i2b2$crc$getAllYearCosts(c(patientset.t.id, patientset.c.id))
timingTag("costs db query")
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

costs.treated[,"datum"] <- as.Date(costs.treated[,"datum"])
costs.control[,"datum"] <- as.Date(costs.control[,"datum"])

costsPerQuarter.treated <- aggregate(. ~ datum, data=costs.treated, mean)
costsPerQuarter.control <- aggregate(. ~ datum, data=costs.control, mean)
costsPerQuarter <- aggregate(. ~ datum, data=costs, mean)

costsPerQuarter.treated$patient_num <- NULL
costsPerQuarter.control$patient_num <- NULL
costsPerQuarter$patient_num <- NULL

costsToPlot.t <- costsPerQuarter.treated[,c("datum", "summe_aller_kosten")]
costsToPlot.c <- costsPerQuarter.control[,c("datum", "summe_aller_kosten")]

plot(costsToPlot.t,type="l",xlab="Quartal/Jahr",ylab="Kosten",bty="n")
lines(costsToPlot.c,type="l",col=accentColor[2])
lineHeight <- max(max(costsToPlot.t[,"summe_aller_kosten"]),max(costsToPlot.c[,"summe_aller_kosten"]))+20
arrows(as.Date(treatmentDate),-10,as.Date(treatmentDate),lineHeight,lwd=1.25,length=0,xpd=TRUE,col=darkGray)
text(as.Date(treatmentDate),lineHeight+10,"Treatment Date",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=darkGray)

text(max(costsToPlot.t[,"datum"]),lineHeight-10,"Treatment Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=baseColor)
text(max(costsToPlot.t[,"datum"]),lineHeight-20,"Control Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=accentColor[2])

print("outputting")
options(scipen=999)
treatmentMean <- round(mean(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
treatmentMedian <- round(median(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
controlMean <- round(mean(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
controlMedian <- round(median(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
scoreDiffMean <- round(mean(abs(probabilities[matched$index.treated,"probabilities"] - probabilities[matched$index.control,"probabilities"])))

stats["pnums.treated"] <- nrow(probabilities[probabilities[,"target.vector"]==1,])
stats["pnums.control"] <- nrow(probabilities[probabilities[,"target.vector"]==0,])

validationParams <- data.frame(c(treatmentMean, treatmentMedian, controlMean, controlMedian,scoreDiffMean))
dimnames(validationParams) <- list(c("mean of treatment scores",
                                     "median of treatment scores",
                                     "mean of control scores",
                                     "median of control scores",
                                     "mean of score difference"), 'Value')

matchedPatients <- cbind(pnums.treated, round(probabilities[matched$index.treated, "probabilities"], 4), round(costs.pY[pnums.treated,"summe_aller_kosten"], 2), round(costs.tY[pnums.treated,"summe_aller_kosten"], 2),
				pnums.control, round(probabilities[matched$index.control, "probabilities"], 4), round(costs.pY[pnums.control,"summe_aller_kosten"], 2), round(costs.tY[pnums.control,"summe_aller_kosten"], 2))

colnames(matchedPatients) <- c("Treatment group p_num", "Score", "Costs year before", "Costs treatment year", 
					  "Control group p_num", "Score", "Costs year before", "Costs treatment year")
rownames(matchedPatients) <- c()

print(matchedPatients[1:2,])
print(validationParams)

girix.output[["Matched patients"]] <- head(matchedPatients, n=100)
#"Verbose labels of columns: patient number (treatment group), Propensity Score, 
#Overall costs of patient in the year before treatment, Overall costs of patient in the year of treatment.
#Simulatenously for the following four columns for patients of control group"
girix.output[["Validation Parameters"]] <- validationParams
girix.output[["Costs per year"]] <- costsPerQuarter
timingTag("Output")
girix.output[["Stats"]] <- as.data.frame(stats)
girix.output[["Timing"]] <- as.data.frame(timings)
print(as.data.frame(timings))
