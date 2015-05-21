require(Matrix)
require(Matching)

if(!exists('girix.input')) {
  source("/home/ubuntu/i2b2/GIRIXScripts/lib/girix.r")
  source("PSM/girix_input.r")
}

source("../lib/i2b2.r", chdir=TRUE)
source("costs_chart.r")
source("../lib/risk.r")
source("../lib/featureMatrix.r")

timings <- c()
stats <- c()
time.start <<- proc.time()

timingTag <- function(name) {
  time.end <<- proc.time()
  timings[name] <<- sum(c(time.end-time.start)[3])
  time.start <<- proc.time()
}

failScript <- function(errorMessage="Something went wrong") {
	girix.output[["Matched patients"]] <- errorMessage
	girix.output[["Validation Parameters"]] <- errorMessage
	girix.output[["Costs per year"]] <- errorMessage
	girix.output[["Stats"]] <- errorMessage
	girix.output[["Timing"]] <- errorMessage
}

psm <- function(features.target, features.control, age=FALSE, sex=FALSE) {  
  print("calculating probabilities")
  target.vector <- c(rep(1, each=nrow(features.target)),rep(0, each=nrow(features.control)))
  featureMatrix <- rbind2(features.target,features.control)
  risk.type <- 'speedglm'
  fit <- risk[[risk.type]]$fit(featureMatrix, target.vector)  
  timingTag("log reg")
  probabilities <- risk[[risk.type]]$predict(fit, featureMatrix)
  splitted <- list()
  splitted[[1]] <- cBind(featureMatrix, probabilities=probabilities$probability, target.vector)
  if (sex) {
    gender <- list()
    for(patients in splitted) {
      gender <- c(gender, splitByGender(patients))
    }
    splitted <- gender
  }
  if (age) {  
    age <- list()
    for(patients in splitted) {  
      age <- c(age, splitByAge(patients))
    }
    splitted <- age
  }
  result <- list()
  result$matched <- do.call(rbind, lapply(splitted, primitivePSM))
  rownames(result$matched) <- NULL
  result$probabilities <- cBind(patient_num=probabilities$patient_num, probabilities=probabilities$probability, target.vector)
  return(result)
}

primitivePSM <- function(patients) {
  matched <- Match(Tr=patients[,'target.vector'], X=patients[,'probabilities'], M=1, exact=TRUE, ties=FALSE, version="fast", distance.tolerance=0.001)
  timingTag("matching")
  if(!is.list(matched)) {
    return(NULL)
  }
  pnum.control <- rownames(patients)[matched$index.control]
  score.control <- patients[matched$index.control,'probabilities']
  pnum.treated <- rownames(patients)[matched$index.treated]
  score.treated <- patients[matched$index.treated,'probabilities']
  result <- data.frame(pnum.treated, score.treated, pnum.control, score.control, stringsAsFactors=FALSE)
  return(result)
}

splitByGender <- function(features) {
  sex <- features[,"sex"]
  gender <- list()
  gender[[1]] <- features[sex == 1,]
  gender[[2]] <- features[sex != 1,]
  return(gender)
}

splitByAge <- function(features) {
  age <- features[,"age"]
  gender <- list()
  gender[[1]] <- features[age < 30,]
  gender[[2]] <- features[age >= 30 & age < 40,]
  gender[[3]] <- features[age >= 40 & age < 50,]
  gender[[4]] <- features[age >= 50 & age < 60,]
  gender[[5]] <- features[age >= 60 & age < 70,]
  gender[[6]] <- features[age >= 70,]
  for(g in gender) {
    if(nrow(g) == 0) {
      g <- NULL
    }
  }
  return(gender)
}

queryCosts <- function(patientset.t.id, patientset.c.id) {
	print("querying costs") #debug  
	treatmentDate <- getDate(treatmentYear, treatmentQuarter)
	costs <<- i2b2$crc$getAllYearCosts(c(patientset.t.id, patientset.c.id))
	timingTag("costs db query")
  
	costs.treated <- costs[costs[,"patient_num"] %in% pnums.treated,]
	costs.control <- costs[costs[,"patient_num"] %in% pnums.control,]

	costs.treated[,"datum"] <- as.Date(costs.treated[,"datum"])
	costs.control[,"datum"] <- as.Date(costs.control[,"datum"])

	costsPerQuarter.treated <<- aggregate(. ~ datum, data=costs.treated, mean)
	costsPerQuarter.control <<- aggregate(. ~ datum, data=costs.control, mean)
	costsPerQuarter <<- aggregate(. ~ datum, data=costs, mean)

	costsPerQuarter.treated$patient_num <<- NULL
	costsPerQuarter.control$patient_num <<- NULL
	costsPerQuarter$patient_num <<- NULL

	costsToPlot.t <- costsPerQuarter.treated[,c("datum", "summe_aller_kosten")]
	costsToPlot.c <- costsPerQuarter.control[,c("datum", "summe_aller_kosten")]

	plot(costsToPlot.t,type="l",xlab="Quartal/Jahr",ylab="Kosten",bty="n")
	lines(costsToPlot.c,type="l",col=accentColor[2])
	lineHeight <- max(max(costsToPlot.t[,"summe_aller_kosten"]),max(costsToPlot.c[,"summe_aller_kosten"]))+20
	arrows(as.Date(treatmentDate),-10,as.Date(treatmentDate),lineHeight,lwd=1.25,length=0,xpd=TRUE,col=darkGray)
	text(as.Date(treatmentDate),lineHeight+10,"Treatment Date",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=darkGray)

	text(max(costsToPlot.t[,"datum"]),lineHeight-10,"Treatment Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=baseColor)
	text(max(costsToPlot.t[,"datum"]),lineHeight-20,"Control Group",adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=accentColor[2])
	
	matchedCosts <- list()

	yearBeforeTreatmentDate <- getDate(as.integer(treatmentYear) - 1, treatmentQuarter)
	yearAfterTreatmentDate <- getDate(as.integer(treatmentYear) + 1, treatmentQuarter)
  
	matchedCosts$pY <- costs[yearBeforeTreatmentDate <= costs[, "datum"] & costs[, "datum"] < treatmentDate,]
	matchedCosts$tY <- costs[treatmentDate <= costs[, "datum"] & costs[, "datum"] < yearAfterTreatmentDate,]
	if(nrow(matchedCosts$pY) == 0 || nrow(matchedCosts$tY) == 0) {
	  return(NULL)
	}
	matchedCosts$pY <- aggregate(summe_aller_kosten ~ patient_num, data = matchedCosts$pY, sum)
	row.names(matchedCosts$pY) <- matchedCosts$pY[,"patient_num"]
	matchedCosts$tY <- aggregate(summe_aller_kosten ~ patient_num, data = matchedCosts$tY, sum)
	row.names(matchedCosts$tY) <- matchedCosts$tY[,"patient_num"]
  
  return(matchedCosts)
}

exec <- function() {
	# girix input processing
	patientset.t.id <- strtoi(girix.input['Treatment group'])
	patientset.c.id <- strtoi(girix.input['Control group'])
	treatmentDate <- eval(parse(text=girix.input['Treatment Quarter']))
	treatmentYear <<- treatmentDate["year"]
	treatmentQuarter <<- treatmentDate["quarter"]
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
		filter <- append(filter, '\\ICD\\')
	}
	if(features["ATC"] == TRUE) {
		filter <- append(filter, '\\ATC\\')
	}
	for(addFeature in addFeatures) {
	  if(addFeature != '') {
	    filter <- append(filter, addFeature)
	  }
	}
	timingTag("-")
	features <- i2b2$crc$getConcepts(concepts=filter, level=level)
	patientset.c <- i2b2$crc$getPatients(patient_set=patientset.c.id)
	patientset.t <- i2b2$crc$getPatients(patient_set=patientset.t.id)
	if(nrow(patientset.c) == 0) {
	    failScript('Control group is empty')
	    return()
  	}
	if(nrow(patientset.t) == 0) {
	    failScript('Target group is empty')
	    return()
  	}

	featureMatrix.t <- generateFeatureMatrix(level=level, interval=interval, patients=patientset.t, patient_set=patientset.t.id, features=features, filter=filter)
	timingTag("featureMatrix.t")
	featureMatrix.c <- generateFeatureMatrix(level=level, interval=interval, patients=patientset.c, patient_set=patientset.c.id, features=features, filter=filter)
	timingTag("featureMatrix.c")

	result <- psm(features.target=featureMatrix.t,features.control=featureMatrix.c, sex=splitBy["Gender"], age=splitBy["Age"])

	probabilities <- result$probabilities

	matched <- result$matched

	timingTag("Matching")

	print("preparing pnums") #debug
	pnums.treated <<- matched$pnum.treated
	pnums.control <<- matched$pnum.control  # contains together with pnums.treated the matching information(order matters)

	matchedCosts <<- queryCosts(patientset.c.id=patientset.c.id,patientset.t.id=patientset.t.id)

	print("outputting")
	options(scipen=10)
	treatmentMean <- round(mean(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
	treatmentMedian <- round(median(probabilities[probabilities[,"target.vector"]==1,"probabilities"]),4)
	controlMean <- round(mean(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
	controlMedian <- round(median(probabilities[probabilities[,"target.vector"]==0,"probabilities"]),4)
	scoreDiffMean <- round(mean(abs(matched$score.treated - matched$score.control)), 4)

	stats["treatment group patient count"] <- nrow(probabilities[probabilities[,"target.vector"]==1,])
	stats["control group patient count"] <- nrow(probabilities[probabilities[,"target.vector"]==0,])
#  if(!is.null(pnums.treated)) {
#    stats["number of matches"] <- nrow(pnums.treated)
#  }
  
	validationParams <- data.frame(c(treatmentMean, treatmentMedian, controlMean, controlMedian,scoreDiffMean))
	dimnames(validationParams) <- list(c("mean of treatment scores",
	                                     "median of treatment scores",
	                                     "mean of control scores",
	                                     "median of control scores",
	                                     "mean of score difference"), 'Value')
  if(!is.null(matchedCosts)) {
	  matchedPatients <- data.frame(pnums.treated, round(matched$score.treated, 4), round(matchedCosts$pY[pnums.treated,"summe_aller_kosten"], 2), round(matchedCosts$tY[pnums.treated,"summe_aller_kosten"], 2),
					pnums.control, round(matched$score.control, 4), round(matchedCosts$pY[pnums.control,"summe_aller_kosten"], 2), round(matchedCosts$tY[pnums.control,"summe_aller_kosten"], 2))
  }
  
	colnames(matchedPatients) <- c("Treatment group p_num", "Score", "Costs year before", "Costs treatment year", 
						  "Control group p_num", "Score", "Costs year before", "Costs treatment year")
	rownames(matchedPatients) <- c()

	print(matchedPatients[1:2,])
	print(validationParams)

	costs_chart(costsPerQuarter.control, costsPerQuarter.treated)

	girix.output[["Matched patients"]] <<- head(matchedPatients, n=100)
	girix.output[["Validation Parameters"]] <<- validationParams
	girix.output[["Costs per year"]] <<- costsPerQuarter
	timingTag("Output")
	girix.output[["Stats"]] <<- as.data.frame(stats)
	girix.output[["Timing"]] <<- as.data.frame(timings)
	print(as.data.frame(timings))
}

exec()

rm(girix.input, girix.concept.names, girix.events, girix.modifiers, girix.observations, girix.observers, girix.patients); gc()

