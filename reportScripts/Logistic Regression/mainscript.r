setwd('/home/ubuntu/i2b2/reportScripts/Logistic Regression/')
source("utils.r")
source("i2b2.r")
clear_env <- TRUE
if(!exists('report.input')) {
  source("report.r")
  clear_env <- FALSE
}

require(Matrix)

fitModel.speedglm <- function(model, target) {
  
  # required packages needed, must be installed first
  require(speedglm)
  
  # compute the fit model using multiple cores
  # this is the actual logistic regression process
  
  # bind a intercept column to our data
  model <- cBind(1, model)
  colnames(model)[1] <- 'intercept'
  
  # We need to filter out features where not enough observations were captured
  n.IG     <- colSums(sign(model[target==1,]))
  n.VG     <- colSums(sign(model[target==0,]))
  excl.IG  <- which(n.IG<5)
  excl.VG  <- which(n.VG<5)
  excl.ALL <<- intersect(excl.IG, excl.VG)
  if(length(excl.ALL)>0){ 
    model <- model[,-excl.ALL]
  }
  
  fit <- speedglm.wfit(y=target, X=model, family=binomial(), sparse=TRUE)
  
  return(fit)
  
}
  
predict.speedglm <- function(fit, newdata) {  

  newdata <- cBind(1, newdata)
  colnames(newdata)[1] <- 'intercept'
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

fitModel.my.glmnet <- function(model, target, newdata) {
  
  require(glmnet)
  require(doMC)
  
  registerDoMC(cores=2)
  
  fit <- cv.glmnet(model, target, parallel=TRUE, family = "binomial", type.measure = "deviance")

  return(fit)
  
}

predict.my.glmnet <- function(fit, newdata) {
  
  require(glmnet)
  #pb <- predict(fit, newx=newdata, s=fit$lambda[which.max(fit$nzero)], type = "response")
  pb <- predict(fit, newx=newdata, type="response")
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd, features)), x=as.numeric(count), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(m)
}

generateFeatureMatrix <- function(interval, patients, patient_set=-1, features, filter, level=3) {
  
  observations <- getObservations(types=filter, interval=interval, patient_set=patient_set, level=level)
  
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

generateTargetVector <- function(interval, patients, patient_set=-1, concept.path) {
  
  concept.cd <- getConceptCd(concept.path)
  concept.level <- nchar(gsub('.*:', '', concept.cd))
  observations <- getObservationsForConcept(concept=concept.cd, interval=interval, patient_set=patient_set, level=concept.level)
  
  target_matrix <- generateObservationMatrix(observations, c(concept.cd), patients$patient_num)
  return(sign(target_matrix[,1]))
}

validateModel <- function(fit, model, target) {

  require(ROCR)

  prediction <- predict.speedglm(fit, model)
  pred <- prediction(prediction$probability, target)

  roc <- performance(pred, "tpr", "fpr")

  precrec <- performance(pred, 'prec', 'rec')

  auc <- as.numeric(performance(pred, 'auc')@y.values)

  #target.positive <- sort.data.frame(prediction[target == 1,],'probability')
  #ppv.cutoff <- target.positive[round(nrow(target.positive)*0.1),'probability']
  prediction.sorted <- sort.data.frame(prediction, 'probability')
  ppv.cutoff <- prediction.sorted[round(nrow(prediction.sorted)*0.1), 'probability']
  ppv.perf <- performance(pred, 'ppv')
  ppv.x <- ppv.perf@x.values[[1]]
  ppv.y <- ppv.perf@y.values[[1]]
  ppv <- ppv.y[which.min(abs(ppv.x-ppv.cutoff))]

  return(list(auc=auc, ppv=ppv, roc=roc, precrec=precrec))

}

model.interval <- list(start=i2b2DateToPOSIXlt(report.input['Model data start']), end=i2b2DateToPOSIXlt(report.input['Model data end']))
model.patient_set <- ifelse(nchar(report.input['Model Patient set']) != 0, strtoi(report.input['Model Patient set']), -1)

model.target.interval <- list(start=i2b2DateToPOSIXlt(report.input['Target data start']), end=i2b2DateToPOSIXlt(report.input['Target data end']))
target.concept.path <- report.input['Target concept']

newdata.interval <- list(start=i2b2DateToPOSIXlt(report.input['Prediction data start']), end=i2b2DateToPOSIXlt(report.input['Prediction data end']))
newdata.patient_set <- ifelse(nchar(report.input['New Patient set']) != 0, strtoi(report.input['New Patient set']), -1)

features.filter <- c("ATC", "ICD")
features.level <- strtoi(report.input['Feature level'])

time.query.0 <- proc.time()

features <- getConcepts(types=features.filter, level=features.level)
model.patients <- getPatients(patient_set=model.patient_set)
newdata.patients <- getPatients(patient_set=newdata.patient_set)

model <- generateFeatureMatrix(level=features.level, interval=model.interval, patients=model.patients, patient_set=model.patient_set, features=features, filter=features.filter)
newdata <- generateFeatureMatrix(level=features.level, interval=newdata.interval, patients=newdata.patients, patient_set=newdata.patient_set, features=features, filter=features.filter)
model.target <- generateTargetVector(interval=model.target.interval, patients=model.patients, patient_set=model.patient_set, concept.path=target.concept.path)

time.query.1 <- proc.time()
time.query <- sum(c(time.query.1-time.query.0)[3])

# print result

time.prediction.0 <- proc.time()

fit <- fitModel.speedglm(model, model.target)
prediction <- predict.speedglm(fit, newdata)

time.prediction.1 <- proc.time()
time.prediction <- sum(c(time.prediction.1-time.prediction.0)[3])

prediction.sorted <- sort.data.frame(prediction, which(colnames(prediction) == 'probability'))
prediction.sorted$probability <- prediction.sorted$probability * 100

newdata.target.interval <- list(start=POSIXltToi2b2Date(as.Date(newdata.interval$start) + as.numeric(difftime(model.target.interval$start, model.interval$start))), end=POSIXltToi2b2Date(as.Date(newdata.interval$end) + as.numeric(difftime(model.target.interval$end, model.interval$end))))
info.model <- sprintf('Model Data for %s (%d patients) from %s to %s', printPatientSet(model.patient_set), nrow(model.patients), report.input['Model data start'], report.input['Model data end'])
info.model.target <- sprintf('Target Data for %s from %s to %s', target.concept.path, report.input['Target data start'], report.input['Target data end'])
info.newdata <- sprintf('Prediction for %s (%d patients) based on data from %s to %s', printPatientSet(newdata.patient_set), nrow(newdata.patients), report.input['Prediction data start'], report.input['Prediction data end'])
info.newdata.target <- sprintf('Prediction from %s to %s', newdata.target.interval$start, newdata.target.interval$end)

info <- data.frame(c(info.model, info.model.target, info.newdata, info.newdata.target))
colnames(info) <- c('Info')

probabilities <- prediction.sorted$probability
summary <- data.frame(c(max(probabilities), min(probabilities), mean(probabilities), median(probabilities)))
dimnames(summary) <- list(c('Max', 'Min', 'Mean', 'Median'), 'Value')

coefficients.top <- data.frame(head(sort(coef(fit), TRUE), 5))
colnames(coefficients.top) <- c('Factor')

statistics <- data.frame(c(time.query, time.prediction))
dimnames(statistics) <- list(c('Data Query time', 'Prediction time'), 'Time (in s)')

prediction.top <- head(prediction.sorted, 100)
colnames(prediction.top) <- c('Patient number', 'Probability (in %)')

options(scipen=10)
hist(probabilities, seq(0, 100, 10), ylim=c(0,nrow(model.patients)), xlab='Probabilities (in %)')

performance <- validateModel(fit, model, model.target)
quality <- data.frame(c(performance$auc, performance$ppv))
dimnames(quality) <- list(c('AUC', 'PPV'), 'Value')

report.output[['Information']] <- info
report.output[['Summary']] <- summary
report.output[['Top coefficients']] <- coefficients.top
report.output[['Statistics']] <- statistics
report.output[['Prediction']] <- prediction.top
report.output[['Quality']] <- quality

plot(performance$roc, main='ROC curve')
plot(performance$precrec, main='Precision/Recall curve')

rm(report.input, report.concept.names, report.events, report.modifiers, report.observations, report.observers, report.patients); gc()
if(clear_env) {
  rm(clear_env, coefficients.top, excl.ALL, features, features.filter, features.level, fit, info, info.model, info.model.target, info.newdata, info.newdata.target, model, model.interval, model.patients, model.patient_set, model.target, model.target.interval, newdata, newdata.interval, newdata.patients, newdata.patient_set, newdata.target.interval, performance, prediction, prediction.sorted, prediction.top, probabilities, quality, statistics, summary, target.concept.path, time.prediction, time.prediction.0, time.prediction.1, time.query, time.query.0, time.query.1); gc()
}