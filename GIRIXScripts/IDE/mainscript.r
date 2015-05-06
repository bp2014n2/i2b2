if(!exists('girix.input')) {
  source("/home/ubuntu/i2b2/GIRIXScripts/lib/girix.r")
  setwd("IDE")
  girix.input['params'] <- '{}'
  girix.input['Patient set'] <- '-1'
  girix.input["requestOutput"] <- 'all'
}

source("IDE/main.r", local=T)

input <- girix.input
girix.output[["result"]] <- generateOutput()

rm(girix.input, girix.concept.names, girix.events, girix.modifiers, girix.observations, girix.observers, girix.patients); gc()

