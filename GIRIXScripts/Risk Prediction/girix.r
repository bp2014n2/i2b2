setwd('Risk Prediction')

girix.input['Model data start'] <- '01/01/2007'
girix.input['Model data end'] <- '01/01/2008'
girix.input['Target data start'] <- '01/01/2008'
girix.input['Target data end'] <- '01/01/2009'
girix.input['Prediction data start'] <- '01/01/2010'
girix.input['Prediction data end'] <- '01/01/2011'
girix.input['Target concept'] <- '\\ICD\\M00-M99\\M50-M54\\M54\\'
girix.input['Model Patient set'] <- '-1'
girix.input['New Patient set'] <- '-1'
girix.input['Feature level'] <- '3'
girix.input['Method'] <- 'speedglm'