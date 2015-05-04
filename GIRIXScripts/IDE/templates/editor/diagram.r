# ---- code ----
source("../../lib/style.r")
library(xtable)

print_table <- function(name) {
  print(xtable(name), type = "html")
}


print.data.frame <- print_table
print.matrix <- print_table

# print <- function(x, ...) {
#   if(typeof(x) == "data.frame" || typeof(x) == "matrix" || typeof(x) == "list"){
#     print_table(x)
#   } else {
#     base::print(x, ...)
#   }
# }

if(!is.null(params)) {
  eval(parse(text=params$code))
}
