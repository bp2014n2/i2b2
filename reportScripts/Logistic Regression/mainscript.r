setwd('/home/ubuntu/i2b2/reportScripts/Logistic Regression/')
source("utils.r")
source("i2b2.r")

require(Matrix)

predictRisk <- function(model, target, newdata) {
  
  # required packages needed, must be installed first
  require(glmnet)
  require(doMC)
  
  # we want up to four cores to be used for parallel computation
  registerDoMC(cores=4)
  
  # compute the fit model using multiple cores
  # this is the actual logistic regression process
  
  fit <- cv.glmnet(model, target, parallel=TRUE, family="binomial", type.measure="class")
  
  # predict probabilities for target vector
  return(predict(fit, newx=newdata, type="response"))
  
}

generateFeatureMatrix <- function(observations, features, patients) {
  model <- Matrix(rep(0,times=length(features)*length(patients)), ncol=length(features), nrow=length(patients), sparse=TRUE)
  
  rownames(model) <- patients
  colnames(model) <- features
  
  transformToModel <- function(row, patients, features, model) {
    model[row['patient_num'], row['concept_cd']] <<- strtoi(row['count'])
  }
  
  apply(observations, 1, transformToModel, patients=patients, features=features, model=model)
  
  return(model)
}

queries.observations <- "WITH ICD AS (
  SELECT *
  FROM i2b2demodata.observation_fact
  WHERE concept_cd LIKE '%s%%'
  AND (start_date >= '%i-01-01T00:00:00' AND start_date <= '%i-01-01T00:00:00') 
)
SELECT patient_num, concept_cd, COUNT(*) AS count
FROM (
    (SELECT patient_num, substring(concept_cd from 0 for position('.' in concept_cd)) AS concept_cd
    FROM ICD
    WHERE POSITION('.' in concept_cd) <> 0)
  UNION ALL
    (SELECT patient_num, concept_cd AS concept_cd
    FROM ICD
    WHERE POSITION('.' in concept_cd) = 0)
) a
GROUP BY patient_num, concept_cd"

queries.patients <- "SELECT DISTINCT patient_num
FROM i2b2demodata.patient_dimension"

queries.features <- "WITH ICD AS (
  SELECT *
  FROM i2b2demodata.concept_dimension
  WHERE concept_cd LIKE '%s%%'
)
SELECT DISTINCT concept_cd
FROM (
    (SELECT substring(concept_cd from 0 for position('.' in concept_cd)) AS concept_cd
    FROM ICD
    WHERE POSITION('.' in concept_cd) <> 0)
  UNION ALL
    (SELECT concept_cd AS concept_cd
    FROM ICD
    WHERE POSITION('.' in concept_cd) = 0)
) a"

queries.concept_cd <- "SELECT concept_cd
FROM i2b2demodata.concept_dimension
WHERE concept_path LIKE '%s'"

model_year <- strtoi(report.input['Model year'])
prediction_year <- strtoi(report.input['Prediction year'])
model_target_interval <- strtoi(report.input['Model target interval'])
target_concept <- report.input['Target concept']
feature_filter <- 'ICD9:'
target_year <- model_year + model_target_interval

con <- initializeCRCConnection()

observations <- executeQuery(con, strunwrap(queries.observations), feature_filter, model_year, model_year + 1)
new_observations <- executeQuery(con, strunwrap(queries.observations), feature_filter, prediction_year, prediction_year + 1)
target_icd <- executeQuery(con, strunwrap(queries.concept_cd), gsub("[\\]", "\\\\\\\\", target_concept))$concept_cd
target_observations <- executeQuery(con, strunwrap(queries.observations), target_icd, target_year, target_year + 1)
features <- executeQuery(con, strunwrap(queries.features), feature_filter)$concept_cd
patients <- executeQuery(con, strunwrap(queries.patients))$patient_num

destroyCRCConnection(con)

model <- generateFeatureMatrix(observations, features, patients)
new_model <- generateFeatureMatrix(new_observations, features, patients)
target_model <- generateFeatureMatrix(target_observations, c(target_icd), patients)

target <- sign(target_model[,1])

# print result

prediction <- predictRisk(model, target, new_model)
sorted_prediction <- data.frame(rownames(prediction), prediction)
colnames(sorted_prediction) <- c('patient_num', 'probability')
sorted_prediction <- sorted_prediction[order(-sorted_prediction$probability),]
rownames(sorted_prediction) <- NULL

report.output[['Information']] <- sprintf('Model: %i, Target: %i, New: %i', model_year, target_year, prediction_year)
report.output[['Prediction']] <- sorted_prediction