setwd('/home/ubuntu/i2b2/reportScripts/Logistic Regression/')
source("utils.r")
source("i2b2.r")
if(!exists('report.input')) {
  source("report.r")
}

require(Matrix)

predictRisk <- function(model, target, newdata) {
  
  # required packages needed, must be installed first
  require(speedglm)
  
  # compute the fit model using multiple cores
  # this is the actual logistic regression process
  
  model <- cBind(1, model)
  colnames(model)[1] <- 'int'
  newdata <- cBind(1, newdata)
  colnames(newdata)[1] <- 'int'
  
  n.IG     <- colSums(model[target==1,])
  n.VG     <- colSums(model[target==0,])
  excl.IG  <- which(n.IG<5)
  excl.VG  <- which(n.VG<5)
  excl.ALL <- intersect(excl.IG, excl.VG)
  if(length(excl.ALL)>0){ 
    model <- model[,-excl.ALL]
    newdata <- newdata[,-excl.ALL]
  }
  
  fit <<- speedglm.wfit(y=target, X=model, family=binomial(), sparse=TRUE);
  
  b <- coef(fit)
  
  pb <- exp(newdata%*%b)
  pb <- as.vector(pb/(1+pb))
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

generateFeatureMatrix <- function(observations, features, patients) {
  model <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd, features)), x=as.numeric(count), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(model)
}

generateModel <- function(interval, patients, patient_set=-1, features, feature_filter_vector) {
  
  observations <- getObservations(types=feature_filter_vector, dates=interval, patient_set=patient_set)
  
  model <- generateFeatureMatrix(observations, features, patients)
  return(model)
}

generateTargetModel <- function(interval, patients, patient_set=-1, concept, feature_filter_vector) {
  
  concept_cd <- getConceptCd(concept)
  observations <- getObservationsForConcept(concept=concept_cd, types=feature_filter_vector, dates=interval, patient_set=patient_set)
  
  model <- (generateFeatureMatrix(observations, c(concept_cd), patients))
  return(sign(model[,1]))
}

model_year.start <- i2b2DateToPOSIXlt(report.input['Model year'])
model_year.end <- model_year.start
model_year.end$year <- model_year.end$year + 1

prediction_year.start <- i2b2DateToPOSIXlt(report.input['Prediction year'])
prediction_year.end <- prediction_year.start
prediction_year.end$year <- prediction_year.end$year + 1

target_year.start <- i2b2DateToPOSIXlt(report.input['Target year'])
target_year.end <- target_year.start
target_year.end$year <- target_year.end$year + 1

target_concept <- report.input['Target concept']
model_patient_set <- -1
if(nchar(report.input['Model Patient set']) != 0) {
  model_patient_set <- strtoi(report.input['Model Patient set'])
}

new_patient_set <- -1
if(nchar(report.input['New Patient set']) != 0) {
  new_patient_set <- strtoi(report.input['New Patient set'])
}

max_elem <- 100

feature_filter_vector <- c("ATC", "ICD")
features <- getConcepts(types=feature_filter_vector)
patients <- getPatients(patient_set=model_patient_set)
new_patients <- getPatients(patient_set=new_patient_set)

model <- generateModel(interval=list(model_year.start, model_year.end), patients=patients, patient_set=model_patient_set, features=features, feature_filter_vector=feature_filter_vector)
new_model <- generateModel(interval=list(prediction_year.start, prediction_year.end), patients=new_patients, patient_set=new_patient_set, features=features, feature_filter_vector=feature_filter_vector)
target <- generateTargetModel(interval=list(target_year.start, target_year.end), patients=patients, patient_set=model_patient_set, concept=target_concept, feature_filter_vector=feature_filter_vector)

# print result

prediction <- predictRisk(model, target, new_model)
sorted_prediction <- prediction[order(-prediction$probability),]
sorted_prediction$probability <- sorted_prediction$probability * 100
rownames(sorted_prediction) <- NULL

report.output[['Information']] <- sprintf('Model: %s, Target: %s, New: %s, Target Concept: %s, Patient Set: %d', report.input['Model year'], report.input['Target year'], report.input['Prediction year'], target_concept, new_patient_set)
report.output[['Summary']] <- summary(sorted_prediction$probability)
report.output[['Prediction']] <- head(sorted_prediction, max_elem)