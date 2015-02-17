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

# define our matrix sizes
feature.total <- 3
model.observations.total <- 6
newdata.observations.total <- 4

# sample data used
#
# model:
# | # |    f1 | f2 | f3 | t |
# |---|-------|----|----|---|
# | 1 |  0.75 |  0 |  0 | 1 |
# | 2 |  1.00 |  0 |  0 | 1 |
# | 3 |  0.00 |  1 |  0 | 0 |
# | 4 |  0.00 |  0 |  0 | 0 |
# | 5 |  0.00 |  1 |  0 | 0 |
# | 6 |  0.40 |  0 |  0 | 0 |
#
# observations to be predicted:
# | # |    f1 | f2 | f3 |
# |---|-------|----|----|
# | 1 |  0.60 |  1 |  1 |
# | 2 |  0.30 |  1 |  0 |
# | 3 |  0.80 |  1 |  0 |
# | 4 |  0.00 |  0 |  0 |

model.observations.data <- c(0.75, 1.0, 0, 0, 0, 0.4, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0)
model.target.data <- c(1, 1, 0, 0, 0, 0)
newdata.observations.data <- c(0.6, 0.3, 0.8, 0, 1, 1, 1, 0, 1, 0, 0, 0)

# sparse matrices only store values different from a default value (usually 0)
# we can assume that most of our values are 0 (FALSE)
model.observations <- Matrix(model.observations.data, model.observations.total, feature.total, sparse=TRUE)
model.target <- Matrix(model.target.data, model.observations.total, 1, sparse=TRUE)
newdata.observations <- Matrix(newdata.observations.data, newdata.observations.total, feature.total, sparse=TRUE)

# print result

report.output[["Prediction"]] <- predictRisk(model.observations, model.target, newdata.observations)