source("ReportGen/main.r", local=T)

input <- girix.input
girix.output[["Report"]] <- generateOutput()

