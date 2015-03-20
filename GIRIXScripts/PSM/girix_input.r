# sets environment input from webclient to make mainscript.r runable independently of webclient

girix.patients <- c()
girix.observations <- c()
girix.input <- c()
girix.output <- list()
girix.concept.names <- c()
girix.modifiers <- c()
girix.events <- c()
girix.observers <- c()

girix.input['Evaluated treatment'] <- "\\ATC\\N\\06\\"
girix.input['Observed patient concept'] <- "\\ICD\\M00-M99\\M00-M03\\M54\\"