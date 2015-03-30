source("ReportGenerator/ReportGen/main.r")

input <- girix.input
input.params <<- fromJSON(input[["params"]])

girix.output[["Report"]] <- generateOutput()

