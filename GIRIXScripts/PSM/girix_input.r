# sets environment input from webclient to make mainscript.r runable independently of webclient

setwd('PSM')
girix.input['Treatment group'] <- "24"   #in webclient: F99-F99 Nicht n@17:58:53, 5-28-2015, 8763 patients
girix.input['Control group'] <- "3"    #in webclient: "G70-G73 Krankhe@10:47:54" , 7. april, 8067 patients
girix.input['Treatment quarter'] <- 'c("year"="2009","quarter"="1")'
girix.input['Automatic, individual treatment date determination'] <- "\\ATC\\D\\09\\"
girix.input['Feature level'] <- "3"
girix.input['Feature Selection'] <- 'c("ICD"=TRUE,"ATC"=TRUE)'
girix.input['Exact matching'] <- 'c("Age"=FALSE,"Gender"=FALSE)'
girix.input['Additional feature 1'] <- ''
girix.input['Additional feature 2'] <- ''
girix.input['Additional feature 3'] <- ''
girix.input['Additional feature 4'] <- ''
girix.input['Additional feature 5'] <- ''
