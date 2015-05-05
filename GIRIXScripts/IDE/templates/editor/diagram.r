# ---- code ----
source("../../lib/style.r")
library(xtable)

print_table <- function(name) {
  print(xtable(name), type = "html")
}

print.data.frame <- print_table
print.matrix <- print_table

patients <- i2b2$crc$getPatients(model.patient_set, silent=T)

disable <- function(funcs) {
  for (i in 1:length(funcs)) {
    params$code <<- gsub(paste0("^.*", funcs[i], "[\\s]*\\(.*$"), paste0("print(\"", funcs[i], " function is disabled for security reasons.\"); "), params$code)
  }
}

if(!is.null(params)) {
  disable(c("source", "setwd", "getwd", "load", "save", "system", "read.table"))
  code <- params$code
  eval(parse(text=code))
}
