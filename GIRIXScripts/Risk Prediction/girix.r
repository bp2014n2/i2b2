setwd('Risk Prediction')

girix.input['Model interval'] <- 'c("Start"="01/01/2007", "End"="01/01/2008")'
girix.input['Target interval'] <- 'c("Start"="01/01/2008", "End"="01/01/2009")'
girix.input['Prediction interval'] <- 'c("Start"="01/01/2010", "End"="01/01/2011")'
girix.input['Target concept'] <- '\\ICD\\M00-M99\\M50-M54\\M54\\'
girix.input['Model Patient set'] <- '1'
girix.input['New Patient set'] <- '1'
girix.input['Feature level'] <- '3'
girix.input['Method'] <- 'speedglm'