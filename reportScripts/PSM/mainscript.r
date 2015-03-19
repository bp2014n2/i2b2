# required packages needed, must be installed first
require(speedglm)
require(Matrix)
require(Matching)

source("PSM/ph_utils.r")
#source("PSM/ph_i2b2.r")
source("PSM/jp_utils.r")

source("lib/i2b2.r")

#print("given patient concept:")
#print(report.input['Observed patient concept'])
#print("given treatment:")
#print(report.input['Evaluated treatment'])

#i2b2ConceptToHuman(report.input['Observed patient concept'])
#i2b2ConceptToHuman(report.input['Observed treatment'])

# to do: to be set in configuration tab
report.input <- c()
report.input['Feature level'] <- 3

#for running independent of report cell
#source("PSM/report_input.r")

# not available on windows:
#require(doMC)


generateFeatureMatrix <- function(interval, patient_set=-1, features, filter, level=3) {
  patients <- i2b2$crc$getPatients(patient_set=patient_set)
  observations <- i2b2$crc$getObservations(concepts=filter, interval=interval, patient_set=patient_set, level=level)
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd, features)), x=as.numeric(count), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(m)
}

#to do: usable for all sorts of concepts
#returns scores and treatments for patients of given concept
Scores.TreatmentsForMonitoredConcept <- function(all.patients, probabilities, concept) {
  diagnosed.ind <- which(all.patients[,i2b2ConceptToHuman(concept)]==1)
  probs.to.match <- probs[diagnosed.ind]
  treatments.to.match <- treatments[diagnosed.ind]
  result <- cbind(probs.to.match, treatments.to.match)
  colnames(result) <- c("Probability", "Treatment")
  return(result)
}

ProbabilitiesOfLogRegFitting <- function(featureMatrix, target.concept) {
  # minimum amount of diagnoses per feature per group (treated + control) to be considered relevant
  minDiagnoses <- 5
  
  # remove target column from featureMatrix
  print("target.concept:")
  print(target.concept)
  target.colname <- i2b2ConceptToHuman(i2b2concept=target.concept)
  target.colind <- which(colnames(featureMatrix)==target.colname) # to do: unnecessary? 
  target.vector <- sign(featureMatrix[,target.colname])
  featureMatrix <- featureMatrix[,-target.colind]
  
  featureMatrix <- cBind(1, featureMatrix)
  colnames(featureMatrix)[1] <- 'int'
  
  # eliminate irrelevant features (they spoil fitting)
  print("eliminating irrelevant features") #debug
  n.IG <- colSums(featureMatrix[target.vector==1,])
  n.VG <- colSums(featureMatrix[target.vector==0,])
  excl.IG <- which(n.IG<minDiagnoses)
  excl.VG <- which(n.VG<minDiagnoses)
  excl.ALL <- intersect(excl.IG, excl.VG)
  if(length(excl.ALL)>0){
    featureMatrix <- featureMatrix[,-excl.ALL]
  }
  
  'print("signing matrix")
  for (i in 1:ncol(featureMatrix)) {
    print(i)
    featureMatrix[,i] <- sign(featureMatrix[,i])
  }'
  
  print("calculating fitting")
  fit <- speedglm.wfit(y=target.vector, X=featureMatrix, family=binomial(), sparse=TRUE);
  
  
  # calculate probabilities
  b <- coef(fit)
  probabilities <- exp(-featureMatrix%*%b)
  probabilities <- as.vector(1/(1+probabilities))
  
  return(probabilities)  
}

#input preparation to be done by GIRI
features.filter <- c("ATC:", "ICD:")
features.level <- strtoi(report.input['Feature level'])
features <- i2b2$crc$getConcepts(concepts=features.filter, level=features.level) # to adapt feature set

print("getting featureMatrix")
# get feature set including all ATC/ICDs out of database
featureMatrix <- generateFeatureMatrix(interval=list(start=as.Date("2008-01-01"), end=as.Date("2009-01-01")), level=features.level, features=features, filter=features.filter)

print("calculating probabilities")
probs <- ProbabilitiesOfLogRegFitting(featureMatrix=featureMatrix, target.concept=report.input['Evaluated treatment'])


to.match <- Scores.TreatmentsForMonitoredConcept(all.patients = featureMatrix, probabilities = probs, 
                                                 concept=report.input['Observed patient concept'])

print("matching")
matched <- Match(Tr=to.match[,"Treatment"], X=to.match[,"Probability"], exact=FALSE, ties=F, version="fast")

print("outputting")
output <- cbind(rownames(to.match[matched$index.control,]), to.match[matched$index.control,"Probability"], rownames(to.match[matched$index.treated,]), to.match[matched$index.treated, "Probability"])
rownames(output) <- NULL
report.output[["Matched patients"]] <- output[1:20,]