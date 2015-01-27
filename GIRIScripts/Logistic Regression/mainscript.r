require(glmnet)
require(Matrix)
require(doMC)

registerDoMC(cores=4)

feature.total=20
model.observations.total=1000000
newdata.observations.total=5000

model.observations.data=sample(0:1,model.observations.total*feature_total,replace=TRUE)
model.target.data=sample(0:1,model.observations.total,replace=TRUE)
newdata.observations.data=sample(0:1,newdata.observations.total*feature_total,replace=TRUE)

#feature.total=3
#model.observations.total=6
#newdata.observations.total=4

#model.observations.data=c(1,1,0,0,0,1,0,0,1,0,1,0,0,0,0,0,0,0)
#model.target.data=c(1,1,0,0,0,1)
#newdata.observations.data=c(1,0,0,0,1,1,1,0,1,0,0,0)

model.observations=Matrix(model.observations.data,model.observations.total,feature_total,sparse=TRUE)
model.target=Matrix(model.target.data,model.observations.total,1,sparse=TRUE)
newdata.observations=Matrix(newdata.observations.data,newdata.observations.total,feature_total,sparse=TRUE)

fit=cv.glmnet(model.observations,model.target,parallel=TRUE)

prediction=predict(fit,newx=newdata.observations)

print(prediction)