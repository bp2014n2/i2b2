# sets environment input from webclient to make mainscript.r runable independently of webclient

girix.patients <- c()
girix.observations <- c()
girix.input <- c()
girix.output <- list()
girix.concept.names <- c()
girix.modifiers <- c()
girix.events <- c()
girix.observers <- c()

girix.input['Treatment group'] <- "3"   #in webclient: L10 Pemphiguskr, 7. april, 487 patients
girix.input['Control group'] <- "12"    #in webclient: "G70-G73 Krankhe@10:47:54" , 7. april, 8067 patients
girix.input['Treatment date'] <- "01/01/2009"