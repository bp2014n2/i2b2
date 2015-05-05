# ---- code ----
source("../../lib/style.r")
library(xtable)

print_table <- function(name) {
  print(xtable(name), type = "html")
}

print.data.frame <- print_table
print.matrix <- print_table

patients <- i2b2$crc$getPatients(model.patient_set, silent=T)

if(!is.null(params)) {
  eval(parse(text=params$code))
}
