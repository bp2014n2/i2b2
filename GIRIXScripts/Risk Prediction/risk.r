risk <- list()
risk$speedglm <- list()
risk$glmnet <- list()
risk$svm <- list()

risk$svm$fit <- function(model, target) {
  
  require(e1071)
  
  fit <- svm(model, target, probability=TRUE)
  
  return(fit)
  
}

risk$svm$predict <- function(fit, newdata) {  
  
  pb <- predict(fit, newdata, probability=TRUE)
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

risk$svm$coef <- function(fit) {
  
  return(fit$coefs)
  
}

risk$speedglm$fit <- function(model, target) {
  
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
  risk$speedglm$excl.ALL <<- intersect(excl.IG, excl.VG)
  if(length(risk$speedglm$excl.ALL)>0){ 
    model <- model[,-risk$speedglm$excl.ALL]
  }
  
  fit <- speedglm.wfit(y=target, X=model, family=binomial(), sparse=TRUE)
  
  return(fit)
  
}

risk$speedglm$predict <- function(fit, newdata) {  
  
  newdata <- cBind(1, newdata)
  colnames(newdata)[1] <- 'intercept'
  if(length(risk$speedglm$excl.ALL)>0){ 
    newdata <- newdata[,-risk$speedglm$excl.ALL]
  }
  
  b <- coef(fit)
  
  pb <- exp(-newdata%*%b)
  pb <- as.vector(1/(1+pb))
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

risk$speedglm$coef <- function(fit) {
  
  return(coef(fit))
  
}

risk$glmnet$fit <- function(model, target) {
  
  require(glmnet)
  require(doMC)
  
  registerDoMC(cores=2)
  
  fit <- cv.glmnet(model, target, parallel=TRUE, family = "binomial", type.measure = "deviance")
  
  return(fit)
  
}

risk$glmnet$predict <- function(fit, newdata) {
  
  require(glmnet)
  #pb <- predict(fit, newx=newdata, s=fit$lambda[which.max(fit$nzero)], type = "response")
  pb <- predict(fit, newx=newdata, type="response")
  pb <- data.frame(rownames(newdata), pb)
  colnames(pb) <- c('patient_num', 'probability')
  return(pb)
  
}

risk$glmnet$coef <- function(fit) {
  
  return(coef(fit))
  
}