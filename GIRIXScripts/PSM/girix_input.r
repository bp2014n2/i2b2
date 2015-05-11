# sets environment input from webclient to make mainscript.r runable independently of webclient

setwd('PSM')

girix.input['Treatment group'] <- "27"   #in webclient: L10 Pemphiguskr, 7. april, 487 patients
girix.input['Control group'] <- "29"    #in webclient: "G70-G73 Krankhe@10:47:54" , 7. april, 8067 patients
girix.input['Treatment Quarter'] <- 'c("year"=2006,"quarter"=2)'
girix.input['Feature level'] <- "2"
girix.input['Feature Selection'] <- 'c("ICD"=TRUE,"ATC"=FALSE)'
girix.input['Exact matching'] <- 'c("Age"=TRUE,"Gender"=TRUE)'
