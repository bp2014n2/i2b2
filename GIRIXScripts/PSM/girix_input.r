# sets environment input from webclient to make mainscript.r runable independently of webclient

girix.patients <- c()
girix.observations <- c()
girix.input <- c()
girix.output <- list()
girix.concept.names <- c()
girix.modifiers <- c()
girix.events <- c()
girix.observers <- c()

girix.input['Treatment group'] <- "24"   #in webclient: L10 Pemphiguskr, 7. april, 487 patients
girix.input['Control group'] <- "26"    #in webclient: "G70-G73 Krankhe@10:47:54" , 7. april, 8067 patients
girix.input['Treatment year'] <- "2009"
girix.input['Treatment quarter'] <- "2"
girix.input['Feature level'] <- "2"
girix.input['Feature Selection'] <- 'c("ICD"=TRUE,"ATC"=FALSE)'
