# sets environment input from webclient to make mainscript.r runable independently of webclient

setwd('PSM')
girix.input['Treatment group'] <- "3"   #in webclient: L10 Pemphiguskr, 7. april, 487 patients
girix.input['Control group'] <- "12"    #in webclient: "G70-G73 Krankhe@10:47:54" , 7. april, 8067 patients
girix.input['Treatment Quarter'] <- 'c("year"="2009","quarter"="1")'
girix.input['Feature level'] <- "3"
girix.input['Feature Selection'] <- 'c("ICD"=TRUE,"ATC"=TRUE)'
girix.input['Exact matching'] <- 'c("Age"=FALSE,"Gender"=FALSE)'
girix.input['Additional feature 1'] <- ''
girix.input['Additional feature 2'] <- ''
girix.input['Additional feature 3'] <- ''
girix.input['Additional feature 4'] <- ''
girix.input['Additional feature 5'] <- ''
