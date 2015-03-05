setwd('/home/ubuntu/i2b2/reportScripts/Logistic Regression/')
source("utils.r")
source("i2b2.r")
clear_env <- TRUE
if(!exists('report.input')) {
  source("report.r")
  #clear_env <- FALSE
}

require(Matrix)

fitModel <- function(model, target, newdata) {
  
  # required packages needed, must be installed first
  require(speedglm)
  
  # compute the fit model using multiple cores
  # this is the actual logistic regression process
  
  # bind a intercept column to our data
  model <- cBind(1, model)
  colnames(model)[1] <- 'int'
  
  # We need to filter out features where not enough observations were captured
  n.IG     <- colSums(sign(model[target==1,]))
  n.VG     <- colSums(sign(model[target==0,]))
  excl.IG  <- which(n.IG<5)
  excl.VG  <- which(n.VG<5)
  excl.ALL <<- intersect(excl.IG, excl.VG)
  if(length(excl.ALL)>0){ 
    model <- model[,-excl.ALL]
  }
  
  fit <- speedglm.wfit(y=target, X=model, family=binomial(), sparse=TRUE);
  
  return(fit)
  
}
  
predictRisk <- function(fit, newdata) {  

  newdata <- cBind(1, newdata)
  colnames(newdata)[1] <- 'int'
  if(length(excl.ALL)>0){ 
    newdata <- newdata[,-excl.ALL]
  }
  
  b <- coef(fit)
  
  pb <- exp(-newdata%*%b)
  pb <- as.vector(1/(1+pb))
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

predictRiskParallel <- function(model, target, newdata) {
  
  require(glmnet)
  require(doMC)
  
  registerDoMC(cores=2)
  
  n.IG     <- colSums(sign(model[target==1,]))
  n.VG     <- colSums(sign(model[target==0,]))
  excl.IG  <- which(n.IG<5)
  excl.VG  <- which(n.VG<5)
  excl.ALL <- intersect(excl.IG, excl.VG)
  if(length(excl.ALL)>0){ 
    model <- model[,-excl.ALL]
    newdata <- newdata[,-excl.ALL]
  }
  
  fit <- cv.glmnet(model, target, parallel=TRUE, family = "binomial", type.measure = "deviance")
  pb <- predict(fit, newx=newdata, s=fit$lambda[which.max(fit$nzero)], type = "response")
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
  
  model <- generateFeatureMatrix(observations, features, patients$patient_num)
  model <- cBind(model, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(model)
}

generateTargetModel <- function(interval, patients, patient_set=-1, concept, feature_filter_vector) {
  
  concept_cd <- getConceptCd(concept)
  observations <- getObservationsForConcept(concept=concept_cd, types=feature_filter_vector, dates=interval, patient_set=patient_set)
  
  model <- generateFeatureMatrix(observations, c(concept_cd), patients$patient_num)
  return(sign(model[,1]))
}

model_year.start <- i2b2DateToPOSIXlt(report.input['Model data start'])
model_year.end <- i2b2DateToPOSIXlt(report.input['Model data end'])

prediction_year.start <- i2b2DateToPOSIXlt(report.input['Prediction data start'])
prediction_year.end <- i2b2DateToPOSIXlt(report.input['Prediction data end'])

target_year.start <- i2b2DateToPOSIXlt(report.input['Target data start'])
target_year.end <- i2b2DateToPOSIXlt(report.input['Target data end'])

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
time.query.0 <- proc.time()
features <- getConcepts(types=feature_filter_vector)
patients <- getPatients(patient_set=model_patient_set)
new_patients <- getPatients(patient_set=new_patient_set)

model <- generateModel(interval=list(model_year.start, model_year.end), patients=patients, patient_set=model_patient_set, features=features, feature_filter_vector=feature_filter_vector)
new_model <- generateModel(interval=list(prediction_year.start, prediction_year.end), patients=new_patients, patient_set=new_patient_set, features=features, feature_filter_vector=feature_filter_vector)
target <- generateTargetModel(interval=list(target_year.start, target_year.end), patients=patients, patient_set=model_patient_set, concept=target_concept, feature_filter_vector=feature_filter_vector)
time.query.1 <- proc.time()
time.query <- sum(c(time.query.1-time.query.0)[3])

# print result

sort.prediction <- function(prediction) {
  prediction.sorted <- prediction[order(-prediction$probability),]
  rownames(prediction.sorted) <- NULL
  return(prediction.sorted)
}

time.prediction.0 <- proc.time()
fit <- fitModel(model, target)
prediction <- predictRisk(fit, new_model);
time.prediction.1 <- proc.time()
time.prediction <- sum(c(time.prediction.1-time.prediction.0)[3])
prediction.sorted <- sort.prediction(prediction)
prediction.sorted$probability <- prediction.sorted$probability * 100
probabilities <- prediction.sorted$probability

printPatientSet <- function(id) {
  return(ifelse(id < 0, 'all Patients', getPatientSetDescription(id)))
}

target_prediction.start <- POSIXltToi2b2Date(as.Date(prediction_year.start) + as.numeric(difftime(target_year.start, model_year.start)))
target_prediction.end <- POSIXltToi2b2Date(as.Date(prediction_year.end) + as.numeric(difftime(target_year.end, model_year.end)))
info.model <- sprintf('Model Data for %s (%d patients) from %s to %s', printPatientSet(model_patient_set), nrow(patients), report.input['Model data start'], report.input['Model data end'])
info.target <- sprintf('Target Data for %s from %s to %s', target_concept, report.input['Target data start'], report.input['Target data end'])
info.prediction <- sprintf('Prediction for %s (%d patients) based on data from %s to %s', printPatientSet(new_patient_set), nrow(new_patients), report.input['Prediction data start'], report.input['Prediction data end'])
info.prediction_target <- sprintf('Prediction from %s to %s', target_prediction.start, target_prediction.end)

# Plot ROC curve
require(ROCR)
validation.prediction <- predictRisk(fit, model);
pred <- prediction(validation.prediction$probability, target)
roc <- performance(pred, "tpr", "fpr")
precrec <- performance(pred, 'prec', 'rec')
auc <- as.numeric(performance(pred, 'auc')@y.values)
validation.prediction.sorted <- sort.prediction(validation.prediction)
ppv.cutoff <- validation.prediction.sorted[round(nrow(validation.prediction.sorted)*0.1),'probability']
ppv.perf <- performance(pred, 'ppv')
ppv.x <- ppv.perf@x.values[[1]]
ppv.y <- ppv.perf@y.values[[1]]
ppv <- ppv.y[which.min(abs(ppv.x-ppv.cutoff))]
plot(roc, main='ROC curve')
plot(precrec, main='Precision/Recall curve')

report.output[['Information']] <- data.frame(info=c(info.model, info.target, info.prediction, info.prediction_target))
report.output[['Summary']] <- data.frame(property=c('Max', 'Min', 'Mean', 'Median'), value=c(max(probabilities), min(probabilities), mean(probabilities), median(probabilities)))
report.output[['Statistics']] <- data.frame(key=c('Data Query time', 'Prediction time'), time=c(time.query, time.prediction))
report.output[['Prediction']] <- head(prediction.sorted, max_elem)
report.output[['Quality']] <- data.frame(key=c('AUC', 'PPV'), value=c(auc, ppv))

rm(report.input, report.concept.names, report.events, report.modifiers, report.observations, report.observers, report.patients); gc()
if(clear_env) {
  rm(clear_env, prediction, model, new_model, target, features, patients, new_patients, fit, excl.ALL, feature_filter_vector, probabilities, info.model, info.prediction, info.prediction_target, info.target, max_elem, model_patient_set, model_year.end, model_year.start, roc, auc, pred, ppv, ppv.perf, ppv.x, ppv.y, precrec, prediction_year.end, prediction_year.start, target_concept, prediction.sorted, validation.prediction, new_patient_set, target_prediction.end, target_prediction.start, target_year.end, target_year.start, time.prediction, time.prediction.0, time.prediction.1, time.query, time.query.0, time.query.1, ppv.cutoff, validation.prediction.sorted); gc()
}