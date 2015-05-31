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
	girix.output[["Matched patients"]] <<- errorMessage
	girix.output[["Matching description"]] <<- errorMessage
	girix.output[["Validation Parameters"]] <<- errorMessage
	girix.output[["Averaged costs per Year (treatment group)"]] <<- errorMessage
	girix.output[["Averaged costs per Year (control group)"]] <<- errorMessage
	girix.output[["Stats"]] <<- errorMessage
	girix.output[["Timing"]] <<- errorMessage
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
  matched <- Match(Tr=patients[,'target.vector'], X=patients[,'probabilities'], M=1, exact=FALSE, 
  				   ties=FALSE, version="fast", replace=FALSE, caliper=0.2)
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

## todo: !!RELIES ON GLOBAL VARIABLES!!
queryCosts <- function(patientset.t.id, patientset.c.id, intervalLength.Years=3, treatment.path) {
	print("querying costs") #debug  
	treatmentDate <- getDate(treatmentYear, treatmentQuarter)

	costs.treated <<- i2b2$crc$getAllYearCostsDependingOnTreatment(patientSet.id=patientset.t.id, 
						treatment.path=treatment.path, intervalLength.Years=intervalLength.Years)
	# todo: interval for control group as well (not from beginning like now)
	costs.control <<- i2b2$crc$getAllYearCosts(patientset.c.id)
	timingTag("costs db queries")

	costs <<- rbind(costs.treated, costs.control)
	costs.treated[,"datum"] <- as.Date(costs.treated[,"datum"])
	costs.control[,"datum"] <- as.Date(costs.control[,"datum"])
	costs[,"datum"] <- as.Date(costs[,"datum"])

	costsPerQuater.treated <- aggregate(. ~ datum, data=costs.treated, mean)
	costsPerQuater.control <- aggregate(. ~ datum, data=costs.control, mean)
	costsPerQuater <- aggregate(. ~ datum, data=costs, mean)
	
	costsPerQuater.treated$patient_num <- NULL
	costsPerQuater.control$patient_num <- NULL
	costsPerQuater$patient_num <- NULL
  
	costsPerQuater.treated[,"datum"] <- getYear(costsPerQuater.treated[,"datum"])
	costsPerQuater.control[,"datum"] <- getYear(costsPerQuater.control[,"datum"])
	costsPerQuater[,"datum"] <- getYear(costsPerQuater[,"datum"])
  
	costsPerYear.treated <- aggregate(. ~ datum, data=costsPerQuater.treated, sum)
	costsPerYear.control <- aggregate(. ~ datum, data=costsPerQuater.control, sum)
	costsPerYear <- aggregate(. ~ datum, data=costsPerQuater, sum)

	costsToPlot.t <- costsPerYear.treated[,c("datum", "summe_aller_kosten")]
	costsToPlot.c <- costsPerYear.control[,c("datum", "summe_aller_kosten")]

	ymax = max(costsToPlot.c[,"summe_aller_kosten"],costsToPlot.t[,"summe_aller_kosten"])
	ymin = min(costsToPlot.c[,"summe_aller_kosten"],costsToPlot.t[,"summe_aller_kosten"], 0)
  plot(costsToPlot.t,type="l",xlab="Jahr",ylab="Kosten",bty="n",ylim=c(ymin,ymax))
	lines(costsToPlot.c,type="l",col=accentColor[2])
	abline(v=as.Date(treatmentDate), lwd=1.25, col=darkGray)
	mtext("Treatment Date", at=as.Date(treatmentDate),adj=0.5,xpd=TRUE,cex=0.65,family="Lato",font=4,col=darkGray)
	mtext("Treatment Group",adj=1,xpd=TRUE,cex=0.65,family="Lato",font=4,col=baseColor)
	mtext("Control Group",adj=1,padj=2,xpd=TRUE,cex=0.65,family="Lato",font=4,col=accentColor[2])
	
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
	matchedCosts$controlPerYear <- costsPerYear.control
	matchedCosts$treatedPerYear <- costsPerYear.treated
  
  return(matchedCosts)
}

exec <- function() {
	# girix input processing
	patientset.t.id <- strtoi(girix.input['Treatment group'])
	patientset.c.id <- strtoi(girix.input['Control group'])
	treatment.path <<- girix.input['Automatic, individual treatment date determination']
	treatmentDate <- eval(parse(text=girix.input['Treatment quarter']))
	treatmentYear <<- treatmentDate["year"]
	treatmentQuarter <<- treatmentDate["quarter"]
	interval <- list(start=i2b2DateToPOSIXlt('01/01/2000'), end=as.Date(getDate(treatmentYear,treatmentQuarter)))
	features <- eval(parse(text=girix.input['Feature Selection']))
	splitBy <- eval(parse(text=girix.input['Exact matching']))
	level <- strtoi(girix.input['Feature level'])
	addFeatures <- c(girix.input['Additional feature 1'],
		girix.input['Additional feature 2'],
		girix.input['Additional feature 3'],
		girix.input['Additional feature 4'],
		girix.input['Additional feature 5'])
	addFeatures <- addFeatures[addFeatures != '']

	# debug
	print("PatientSet IDs:") 
	print(patientset.t.id)
	print(patientset.c.id)


	filter <- c()
	if(features["ICD"] == TRUE) {
		filter <- append(filter, '\\ICD\\')
	}
	if(features["ATC"] == TRUE) {
		filter <- append(filter, '\\ATC\\')
	}
	timingTag("-")
	features <- i2b2$crc$getConcepts(concepts=filter, level=level)
	patientset.c <<- i2b2$crc$getPatients(patient_set=patientset.c.id)
  if (treatment.path != "") {
    patientset.t.forConcept <<- i2b2$crc$getPatientsForConcept(patient_set=patientset.t.id, concept.path=treatment.path)
  }
  patientset.t  <<- i2b2$crc$getPatients(patient_set=patientset.t.id)
	
	if (treatment.path != "") {
    excludedPatientsOfTGroup <<- patientset.t[!(patientset.t[,"patient_num"] %in% patientset.t.forConcept),"patient_num"]
	  patientset.t <- patientset.t[patientset.t[,"patient_num"] %in% patientset.t.forConcept,]
	}

	print("querying featureMatrices")
	if (treatment.path == "") {
		featureMatrix.t <<- generateFeatureMatrix(level=level, interval=interval, patients=patientset.t, patient_set=patientset.t.id, features=features, filter=filter, addFeatures=addFeatures)
	} else {
		featureMatrix.t <<- generateFeatureMatrixDependingOnTreatment(intervalLength.Years = 3, treatment.path=treatment.path, level=level, patients=patientset.t,  
																	  patient_set=patientset.t.id, features=features, filter=filter, addFeatures=addFeatures)
	}
	timingTag("featureMatrix.t")
	featureMatrix.c <<- generateFeatureMatrix(level=level, interval=interval, patients=patientset.c, patient_set=patientset.c.id, features=features, filter=filter, addFeatures)
	timingTag("featureMatrix.c")
	
	excludedPatients <<- intersect(patientset.c$patient_num,patientset.t$patient_num)
	patientset.c <<- patientset.c[!(patientset.c$patient_num %in% excludedPatients),]
	patientset.t <<- patientset.t[!(patientset.t$patient_num %in% excludedPatients),]
	rownames(patientset.c) <- NULL
	rownames(patientset.t) <- NULL
	featureMatrix.t <<-	featureMatrix.t[!(rownames(featureMatrix.t) %in% excludedPatients),]
	featureMatrix.c <<- featureMatrix.c[!(rownames(featureMatrix.c) %in% excludedPatients),]
	
	if(nrow(patientset.c) == 0) {
	  failScript(errorMessage='Control group is empty')
	  return()
	}
	if(nrow(patientset.t) == 0) {
	  failScript(errorMessage='Treatment group is empty')
	  return()
	}

	print("Matching")
	result <<- psm(features.target=featureMatrix.t,features.control=featureMatrix.c, sex=splitBy["Gender"], age=splitBy["Age"])

	probabilities <<- result$probabilities

	matched <<- result$matched
	
	if(is.null(matched)) {
	  failScript('No matches found')
	  return()
	}
  
	timingTag("Matching")

	print("preparing pnums") #debug
	pnums.treated <<- matched$pnum.treated
	pnums.control <<- matched$pnum.control  # contains together with pnums.treated the matching information(order matters)
	
	if(length(pnums.control[duplicated(pnums.control)]) != 0) {
	  failScript('Duplicates in Control Group')
	  return()
	}
	
	if(length(intersect(pnums.treated, pnums.control)) != 0) {
	  failScript('Patients in Control and Treatment Group')
	  return()
	}

	matchedCosts <<- queryCosts(patientset.c.id=patientset.c.id,patientset.t.id=patientset.t.id, intervalLength.Years=3,
						treatment.path=treatment.path)

	print("outputting")
	options(scipen=10)
  treatmentscores <- probabilities[probabilities[,"target.vector"]==1,"probabilities"]
	controlscores <- probabilities[probabilities[,"target.vector"]==0,"probabilities"]
	scoreDifferences <<- abs(matched$score.treated - matched$score.control)
  scores <- list(treatmentscores, controlscores, matched$score.treated, matched$score.control, scoreDifferences)

	stats["treatment group"] <- nrow(treatmentscores)
	stats["control group"] <- nrow(controlscores)
	stats["treatment group matched"] <- length(unique(pnums.treated))
	stats["control group matched"] <- length(unique(pnums.control))
  #  if(!is.null(pnums.treated)) {
  #    stats["number of matches"] <- nrow(pnums.treated)
  #  }
  means <- sapply(scores, mean)
  medians <- sapply(scores, median)
  validationParams <- data.frame(means, medians)
  colnames(validationParams) <- c("mean of scores", "median of scores")
  validationParams <- apply(validationParams, 2, function(x) as.character(round(x, 4)))
  rownames(validationParams) <- c("Treatment Group", "Control Group", "Treatment Group Matched", "Control Group Matched", "Score Difference")
  
  if(!is.null(matchedCosts)) {
  	matchedPatients <- data.frame(
  	  as.character(round(scoreDifferences, 4)),
      pnums.treated,
  	  round(matched$score.treated, 4),
  	  round(matchedCosts$pY[pnums.treated,"summe_aller_kosten"], 2),
  	  round(matchedCosts$tY[pnums.treated,"summe_aller_kosten"], 2),
  		pnums.control,
  		round(matched$score.control, 4),
  		round(matchedCosts$pY[pnums.control,"summe_aller_kosten"], 2),
  		round(matchedCosts$tY[pnums.control,"summe_aller_kosten"], 2)
    )
  }

	colnames(matchedPatients) <- c("Score Difference", "Treatment group p_num", "Score Treatment", "Costs year before Treatment", "Costs treatment year Treatment", 
						  "Control group p_num", "Score Control", "Costs year before Control", "Costs treatment year Control")
	matchedPatients <- sort.data.frame(matchedPatients, which(colnames(matchedPatients) == 'Score Difference'))
  matchedPatients <<- apply(matchedPatients, 2, as.character)

  matchDesc <<- c()
  
  if(length(excludedPatients) != 0) {
    matchDesc <<- c(matchDesc, paste("WARNING: Left out", length(excludedPatients), 
                       "patients, because they are in both experimental and control group.\n"))
  }

  if(nrow(patientset.c) < 2*nrow(patientset.t)) {
    matchDesc <<- c(matchDesc, 'WARNING: Control group should to be at least twice as large as treatment group')
  }
  
	if(treatment.path != "" && length(excludedPatientsOfTGroup) != 0) {
    matchDesc <<- c(matchDesc, paste("WARNING: Left out ", length(excludedPatientsOfTGroup), " patients of XX patients in 
						treatment group, because they actually did not receive the treatment\n"))
	}

	print(matchedPatients[1:2,])
	print(validationParams)

	costs_chart(matchedCosts$controlPerYear, matchedCosts$treatedPerYear)

	girix.output[["Matched patients"]] <<- head(matchedPatients, n=100)
	if(length(matchDesc) == 0) {
	  matchDesc <- c("No additional Messages")
	}
	girix.output[["Matching description"]] <<- data.frame(Messages=matchDesc)
	girix.output[["Validation Parameters"]] <<- validationParams

	girix.output[["Averaged costs per Year (treatment group)"]] <<- matchedCosts$treatedPerYear
	girix.output[["Averaged costs per Year (control group)"]] <<- matchedCosts$controlPerYear

	timingTag("Output")
	girix.output[["Stats"]] <<- as.data.frame(stats)
	girix.output[["Timing"]] <<- as.data.frame(timings)
	print(as.data.frame(timings))
}

exec()

rm(girix.input, girix.concept.names, girix.events, girix.modifiers, girix.observations, girix.observers, girix.patients)
gc()
