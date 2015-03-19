#!/Library/Frameworks/R.framework/Resources/Rscript

# ---- mainImports ----
options(warn=-1)

library(jsonlite)
library(extrafont)

source("lib/i2b2.r")

source("ReportGenerator/utils/utils.r")
# source("utils/load_data.r")


main <- function(){
  # loaded_data <<- load_data()
  params <<- fromJSON(input[["params"]])
}

main()
