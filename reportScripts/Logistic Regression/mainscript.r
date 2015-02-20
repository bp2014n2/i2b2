setwd('/home/ubuntu/i2b2/reportScripts/Logistic Regression/')
source("utils.r")
source("i2b2.r")

require(Matrix)

predictRisk <- function(model, target, newdata) {
  
  # required packages needed, must be installed first
  require(speedglm)
  
  # compute the fit model using multiple cores
  # this is the actual logistic regression process
  
  fit <- speedglm.wfit(y=target, X=model, family=binomial(), sparse=TRUE);
  b  <- coef(fit)
  pb <- exp(newdata%*%b)
  pb <- as.vector(pb/(1+pb))
  pb[is.na(pb)] <- 0
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

generateFeatureMatrix <- function(observations, features, patients) {
  model <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd, features)), x=as.numeric(count), dims=c(length(patients), length(features)), dimnames=list(levels(patient_num), levels(concept_cd))))
  
  rownames(model) <- patients
  colnames(model) <- features
  
  return(model)
}

model_year.start <- i2b2DateToPOSIXlt(report.input['Model year'])
model_year.end <- model_year.start
model_year.end$year <- model_year.end$year + 1
prediction_year.start <- i2b2DateToPOSIXlt(report.input['Prediction year'])
prediction_year.end <- prediction_year.start
prediction_year.end$year <- prediction_year.end$year + 1
model_target_interval <- strtoi(report.input['Model target interval'])
target_concept <- report.input['Target concept']
feature_filter_vector <- c("ATC", "ICD")
feature_filter <- paste("(", paste(feature_filter_vector, collapse="|"), "):", sep="")
target_year.start <- model_year.start
target_year.start$year <- target_year.start$year + model_target_interval
target_year.end <- target_year.start
target_year.end$year <- target_year.end$year + 1
model_year.start <- posixltToPSQLDate(model_year.start)
model_year.end <- posixltToPSQLDate(model_year.end)
prediction_year.start <- posixltToPSQLDate(prediction_year.start)
prediction_year.end <- posixltToPSQLDate(prediction_year.end)
target_year.start <- posixltToPSQLDate(target_year.start)
target_year.end <- posixltToPSQLDate(target_year.end)
max_elem <- 100

con <- initializeCRCConnection()

observations <- executeQuery(con, strunwrap(queries.observations), feature_filter, feature_filter, model_year.start, model_year.end)
new_observations <- executeQuery(con, strunwrap(queries.observations), feature_filter, feature_filter, prediction_year.start, prediction_year.end)
target_icd <- executeQuery(con, strunwrap(queries.concept_cd), gsub("[\\]", "\\\\\\\\", target_concept))$concept_cd
target_observations <- executeQuery(con, strunwrap(queries.observations), feature_filter, target_icd, target_year.start, target_year.end)
features <- executeQuery(con, strunwrap(queries.features), feature_filter, feature_filter)$concept_cd
patients <- executeQuery(con, strunwrap(queries.patients))$patient_num

destroyCRCConnection(con)

model <- generateFeatureMatrix(observations, features, patients)
new_model <- generateFeatureMatrix(new_observations, features, patients)
target_model <- generateFeatureMatrix(target_observations, c(target_icd), patients)

target <- sign(target_model[,1])

# print result

prediction <- predictRisk(model, target, new_model)
sorted_prediction <- prediction[order(-prediction$probability),]
rownames(sorted_prediction) <- NULL

report.output[['Information']] <- sprintf('Model: %i, Target: %i, New: %i, Target: %s', model_year, target_year, prediction_year, target_icd)
report.output[['Prediction']] <- head(sorted_prediction, max_elem)