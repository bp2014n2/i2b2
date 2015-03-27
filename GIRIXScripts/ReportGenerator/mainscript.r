source("ReportGenerator/ReportGen/main.r")

input <- girix.input
params <<- fromJSON(input[["params"]])
girix.output[["Report"]] <- generateOutput()

