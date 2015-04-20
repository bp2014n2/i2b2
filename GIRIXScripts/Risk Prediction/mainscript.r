if(!exists('girix.input')) {
  source("/home/ubuntu/i2b2/GIRIXScripts/lib/girix.r")
  source("Risk Prediction/girix.r")
}

risk.type <- girix.input['Method']

source("../lib/i2b2.r", chdir=TRUE)
source("risk.r")

require(Matrix)

generateObservationMatrix <- function(observations, features, patients) {
  m <- with(observations, sparseMatrix(i=as.numeric(match(patient_num, patients)), j=as.numeric(match(concept_cd_sub, features)), x=as.numeric(counts), dims=c(length(patients), length(features)), dimnames=list(patients, features)))
  
  return(m)
}

generateFeatureMatrix <- function(interval, patients, patient_set=-1, features, filter, level=3) {
  
  time.start <- proc.time()
  
  observations <- i2b2$crc$getObservations(concepts=filter, interval=interval, patient_set=patient_set, level=level)
  
  time.end <- proc.time()
  
  time.query <<- time.query + sum(c(time.end-time.start)[3])
  
  feature_matrix <- generateObservationMatrix(observations, features, patients$patient_num)
  feature_matrix <- cBind(feature_matrix, sex=strtoi(patients$sex_cd), age=age(as.Date(patients$birth_date), Sys.Date()))
  return(feature_matrix)
}

generateTargetVector <- function(interval, patients, patient_set=-1, concept.path) {
  
  time.start <- proc.time()
  
  observations <- i2b2$crc$getObservationsForConcept(concept.path=concept.path, interval=interval, patient_set=patient_set)
  
  time.end <- proc.time()
  
  time.query <<- time.query + sum(c(time.end-time.start)[3])
  
  target_matrix <- generateObservationMatrix(observations, c('target'), patients$patient_num)
  return(sign(target_matrix[,1]))
}

validateModel <- function(fit, model, target) {

  require(ROCR)

  prediction <- risk[[risk.type]]$predict(fit, model)
  pred <- prediction(prediction$probability, target)

  roc <- performance(pred, "tpr", "fpr")

  precrec <- performance(pred, 'prec', 'rec')

  auc <- as.numeric(performance(pred, 'auc')@y.values)

  #target.positive <- sort.data.frame(prediction[target == 1,],'probability')
  #ppv.cutoff <- target.positive[round(nrow(target.positive)*0.1),'probability']
  prediction.sorted <- sort.data.frame(prediction, 'probability')
  ppv.perf <- performance(pred, 'ppv')
  ppv.x <- ppv.perf@x.values[[1]]
  ppv.y <- ppv.perf@y.values[[1]]
  ppv.cutoff.05 <- prediction.sorted[round(nrow(prediction.sorted)*0.05), 'probability']
  ppv.cutoff.10 <- prediction.sorted[round(nrow(prediction.sorted)*0.1), 'probability']
  ppv.cutoff.20 <- prediction.sorted[round(nrow(prediction.sorted)*0.2), 'probability']
  values <- c()
  cutoffs <- c()
  percentages <- c(5, 10, 20)
  cutoffs <- append(cutoffs, ppv.cutoff.05)
  values <- append(values, ppv.y[which.min(abs(ppv.x-ppv.cutoff.05))])
  cutoffs <- append(cutoffs, ppv.cutoff.10)
  values <- append(values, ppv.y[which.min(abs(ppv.x-ppv.cutoff.10))])
  cutoffs <- append(cutoffs, ppv.cutoff.20)
  values <- append(values, ppv.y[which.min(abs(ppv.x-ppv.cutoff.20))])
  ppv <- data.frame(value=values, cutoff=cutoffs, percentage=percentages)

  return(list(auc=auc, ppv=ppv, roc=roc, precrec=precrec))

}

model.interval <- list(start=i2b2DateToPOSIXlt(girix.input['Model data start']), end=i2b2DateToPOSIXlt(girix.input['Model data end']))
model.patient_set <- ifelse(nchar(girix.input['Model Patient set']) != 0, strtoi(girix.input['Model Patient set']), -1)

model.target.interval <- list(start=i2b2DateToPOSIXlt(girix.input['Target data start']), end=i2b2DateToPOSIXlt(girix.input['Target data end']))
target.concept.path <- girix.input['Target concept']
target.concept.name <- i2b2$ont$getConceptName(target.concept.path)

newdata.interval <- list(start=i2b2DateToPOSIXlt(girix.input['Prediction data start']), end=i2b2DateToPOSIXlt(girix.input['Prediction data end']))
newdata.patient_set <- ifelse(nchar(girix.input['New Patient set']) != 0, strtoi(girix.input['New Patient set']), -1)

features.filter <- c("ATC:", "ICD:")
features.level <- strtoi(girix.input['Feature level'])

time.query <- 0

features <- i2b2$crc$getConcepts(concepts=features.filter, level=features.level)
model.patients <- i2b2$crc$getPatients(patient_set=model.patient_set)
newdata.patients <- i2b2$crc$getPatients(patient_set=newdata.patient_set)

model <- generateFeatureMatrix(level=features.level, interval=model.interval, patients=model.patients, patient_set=model.patient_set, features=features, filter=features.filter)
newdata <- generateFeatureMatrix(level=features.level, interval=newdata.interval, patients=newdata.patients, patient_set=newdata.patient_set, features=features, filter=features.filter)
model.target <- generateTargetVector(interval=model.target.interval, patients=model.patients, patient_set=model.patient_set, concept.path=target.concept.path)

model.split <- 0.6
model.split.row <- round(nrow(model)*model.split)

model.training <- model[1:model.split.row,]
model.target.training <- model.target[1:model.split.row]
model.test <- model[(model.split.row+1):nrow(model),]
model.target.test <- model.target[(model.split.row+1):nrow(model)]

# print result

time.prediction.0 <- proc.time()

fit <- risk[[risk.type]]$fit(model.training, model.target.training)
prediction <- risk[[risk.type]]$predict(fit, newdata)

time.prediction.1 <- proc.time()
time.prediction <- sum(c(time.prediction.1-time.prediction.0)[3])

prediction.sorted <- sort.data.frame(prediction, which(colnames(prediction) == 'probability'))
prediction.sorted$probability <- prediction.sorted$probability * 100

newdata.target.interval <- list(start=POSIXltToi2b2Date(as.Date(newdata.interval$start) + as.numeric(difftime(model.target.interval$start, model.interval$start))), end=POSIXltToi2b2Date(as.Date(newdata.interval$end) + as.numeric(difftime(model.target.interval$end, model.interval$end))))
info.model <- sprintf('Model Data for %s (%d patients, split %d:%d) from %s to %s', printPatientSet(model.patient_set), nrow(model.patients), model.split*100, (1-model.split)*100, girix.input['Model data start'], girix.input['Model data end'])
info.model.target <- sprintf('Target Data for %s from %s to %s', target.concept.name, girix.input['Target data start'], girix.input['Target data end'])
info.newdata <- sprintf('Prediction for %s (%d patients) based on data from %s to %s', printPatientSet(newdata.patient_set), nrow(newdata.patients), girix.input['Prediction data start'], girix.input['Prediction data end'])
info.newdata.target <- sprintf('Prediction from %s to %s', newdata.target.interval$start, newdata.target.interval$end)

info <- data.frame(c(info.model, info.model.target, info.newdata, info.newdata.target))
colnames(info) <- c('Info')

probabilities <- prediction.sorted$probability
summary <- data.frame(c(max(probabilities), min(probabilities), mean(probabilities), median(probabilities)))
dimnames(summary) <- list(c('Max', 'Min', 'Mean', 'Median'), 'Value')

coefficients.top <- data.frame(head(sort(risk[[risk.type]]$coef(fit), TRUE), 5))
rownames(coefficients.top) <- sapply(rownames(coefficients.top), function(x) getConceptName(x))
colnames(coefficients.top) <- c('Factor')

statistics <- data.frame(c(time.query, time.prediction))
dimnames(statistics) <- list(c('Data Query time', 'Prediction time'), 'Time (in s)')

prediction.top <- head(prediction.sorted, 100)
colnames(prediction.top) <- c('Patient number', 'Probability (in %)')

performance <- validateModel(fit, model.test, model.target.test)
quality <- data.frame(c(performance$auc, performance$ppv$value))
dimnames(quality) <- list(c('AUC', paste0("PPV ", performance$ppv$percentage, "% (Cutoff: ", round(performance$ppv$cutoff*100, digits=2), ")")), 'Value')

girix.output[['Information']] <- info
girix.output[['Summary']] <- summary
girix.output[['Top coefficients']] <- coefficients.top
girix.output[['Statistics']] <- statistics
girix.output[['Prediction']] <- prediction.top
girix.output[['Quality']] <- quality

smooth_lines <- TRUE
options(scipen=10)
histogram <- hist(probabilities, seq(0, 100, 10), ylim=c(0,nrow(newdata.patients)), xlab='Probabilities (in %)', col=par("col"))
abline(v=mean(probabilities), lwd=3, col=accentColor[1])
text(x=mean(probabilities), y=par('yaxp')[2]/2, labels='Mean', pos=4, font=2, col=accentColor[1])
plot(performance$roc, main='ROC curve', box.col=darkGray)
if(smooth_lines) {
  #smoothedLine(performance$roc@x.values[[1]], performance$roc@y.values[[1]])
}
plot(performance$precrec, main='Precision/Recall curve', lty="dotted", col=accentColor[1], box.col=darkGray)
if(smooth_lines) {
  smoothedLine(performance$precrec@x.values[[1]], performance$precrec@y.values[[1]])
  #y <- performance$precrec@y.values[[1]]
  #
  #for(i in rev(seq_along(y))) {
  #  y[i] <- max(y[i:length(y)])
  #}
  #performance$precrec@y.values[[1]] <- y
  #lines(performance$precrec@x.values[[1]], performance$precrec@y.values[[1]], col="red", lwd=2)
}

rm(girix.input, girix.concept.names, girix.events, girix.modifiers, girix.observations, girix.observers, girix.patients); gc()