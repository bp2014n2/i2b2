# ---- code ----
source("../../lib/style.r")
library(xtable)

print_table <- function(name) {
  print(xtable(name), type = "html")
}

print.data.frame <- print_table
print.matrix <- print_table

disable <- function(funcs) {
  for (i in 1:length(funcs)) {
    params$code <<- gsub(paste0("^.*", funcs[i], "[\\s]*\\(.*$"), paste0("print(\"", funcs[i], " function is disabled for security reasons.\"); "), params$code)
  }
}

if(!is.null(params)) {
  disable(c("source", "setwd", "getwd", "load", "save", "system", "read.table"))
  sink("/dev/null");
  rm(db)
  attach(i2b2$crc)
  sink()
  code <- params$code
  eval(parse(text=code))
}
