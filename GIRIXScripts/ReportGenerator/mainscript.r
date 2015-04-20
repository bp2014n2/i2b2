if(!exists('girix.input')) {
  source("/home/ubuntu/i2b2/GIRIXScripts/lib/girix.r")
  setwd("ReportGenerator")
  girix.input['params'] <- '{}'
  girix.input['Patient set'] <- '-1'
  girix.input["requestDiagram"] <- 'all'
}

source("ReportGen/main.r", local=T)

input <- girix.input
girix.output[["Report"]] <- generateOutput()

rm(girix.input, girix.concept.names, girix.events, girix.modifiers, girix.observations, girix.observers, girix.patients); gc()

