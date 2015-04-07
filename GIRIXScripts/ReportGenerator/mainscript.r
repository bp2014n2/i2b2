source("ReportGen/main.r", local=T)

input <- girix.input
input.params <- fromJSON(girix.input["params"])
girix.output[["Report"]] <- generateOutput()

