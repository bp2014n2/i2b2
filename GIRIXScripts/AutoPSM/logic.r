require(Matrix)
require(speedglm)
require(Matching)

source("../lib/i2b2.r", chdir=TRUE)
source("utils.r")

# to do: parallelization!!

#to do: usable for all sorts of concepts
#returns scores and treatments for patients of given concept
Scores.TreatmentsForMonitoredConcept <- function(all.patients, patients.probabilities, concept) {
  diagnosed.ind <- which(all.patients[,i2b2ConceptToHuman(concept)]==1)
  result <- patients.probabilities[diagnosed.ind,]
#  result <- cbind(probs.to.match, patientnums.to.match)
  colnames(result) <- c("Probability", "Treatment")
  return(result)
}

ProbabilitiesOfLogRegFitting <- function(featureMatrix, target.concept, signed.matrix=FALSE) {
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
  if(length(excl.ALL)>0) {
    featureMatrix <- featureMatrix[,-excl.ALL]
  }
  
  if (signed.matrix) {
    print("signing matrix")
    for (i in 1:ncol(featureMatrix)) {
      print(i)
      featureMatrix[,i] <- sign(featureMatrix[,i])
    }
  }

  print("calculating fitting")
  fit <- speedglm.wfit(y=target.vector, X=featureMatrix, family=binomial(), sparse=TRUE);
  
  # calculate probabilities
  b <- coef(fit)
  probabilities <- exp(-featureMatrix%*%b)
  probabilities <- as.vector(1/(1+probabilities))
  
  patient.probabilities <- cbind(probabilities, target.vector)

  return(patient.probabilities)  
}